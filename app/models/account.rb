# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                       :uuid             not null, primary key
#  billing_data             :jsonb            not null
#  configurations           :jsonb            not null
#  data                     :jsonb            not null
#  email                    :string
#  features                 :bigint           default(0), not null
#  identifier               :string           not null
#  limits                   :jsonb            not null
#  locale                   :string           default("en"), not null
#  name                     :string           not null
#  referral_approved_at     :datetime
#  referral_code            :string           not null
#  referral_commission      :decimal(10, 2)
#  referral_commission_type :integer          default("fixed"), not null
#  referral_paid_at         :datetime
#  referred_by_commission   :decimal(10, 2)
#  status                   :integer          default("active"), not null
#  shard_key                :string           default("de"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  address_id               :uuid
#  referred_by_id           :uuid
#
# Indexes
#
#  index_accounts_on_created_at      (created_at)
#  index_accounts_on_identifier      (identifier) UNIQUE
#  index_accounts_on_name            (name)
#  index_accounts_on_referral_code   (referral_code) UNIQUE
#  index_accounts_on_referred_by_id  (referred_by_id)
#  index_accounts_on_status          (status)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id) ON DELETE => nullify
#  fk_rails_...  (referred_by_id => accounts.id) ON DELETE => nullify
#

class Account < ApplicationRecord
  include SlugGenerator.new(source: :name, column: :identifier)
  include CodeGenerator.new(prefix: "REF", column: :referral_code)
  include Addressable
  include Billable
  include LimitEnforceable
  include ShardResolvable
  include Deletable
  include Trackable

  identifying_columns :identifier, :referral_code

  def users_count
    current_usage(:users)
  end
  def feature_enabled?(feature)
    base_feature = feature.to_s.delete_suffix("_enabled")
    current_plan&.feature_enabled?(base_feature) == true
  end

  enum :status, { active: 0, suspended: 1, pending_deletion: 2, deleted: 3 }
  enum :referral_commission_type, { fixed: 0 }

  RESERVED_IDENTIFIERS = %w[
    www admin mail auth api webhooks support billing console partners app beta staging test secure 
    cdn my dashboard login register proxy help api-docs smtp imap pop dns ns host server static
    assets blog docs status payment dev prod account accounts user users
  ].freeze

  # rubocop:disable Rails/I18nLocaleTexts
  validates :identifier, presence: true, unless: :deleted?
  validates :referral_code, presence: true, unless: :deleted?
  validates :identifier, uniqueness: { case_sensitive: false }, if: -> { identifier.present? }
  validates :identifier, exclusion: { in: RESERVED_IDENTIFIERS, message: "is a reserved word and cannot be used" }, if: -> { identifier.present? }
  validates :identifier, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }, length: { minimum: 3, maximum: 63 }, if: -> { identifier.present? }
  # rubocop:enable Rails/I18nLocaleTexts
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  # Primary DB Associations
  has_many :access_tokens, as: :owner, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :account_invitations, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_many :ai_wallet_transactions, class_name: "Ai::WalletTransaction", dependent: :destroy
  has_many :account_plans, dependent: :destroy
  has_many :custom_plans, through: :account_plans, source: :plan
  has_one  :sso_configuration, class_name: "Auth::SsoConfiguration", dependent: :destroy
  has_many :domain_verifications, class_name: "Auth::DomainVerification", dependent: :destroy
  has_many :scim_tokens, class_name: "Auth::ScimToken", dependent: :destroy
  has_many :auth_audit_logs, class_name: "Auth::AuditLog", dependent: :destroy
  has_many :auth_user_identities, class_name: "Auth::UserIdentity", dependent: :nullify

  # Sharded DB Associations
  # IMPORTANT: These associations reside in a separate database shard.
  # When accessing them, you must ensure the correct shard context is set,
  # typically using account.with_shard { ... }
  has_many :customers, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :inboxes, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :canned_responses, dependent: :destroy
  has_many :automations, dependent: :destroy
  has_many :macros, dependent: :destroy
  has_many :automation_executions, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :custom_fields, dependent: :destroy
  has_many :identity_sources, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :portals, class_name: "HelpCenter::Portal", dependent: :destroy
  has_many :help_center_articles, class_name: "HelpCenter::Article", dependent: :destroy
  has_many :roles, class_name: "Access::Role", dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :email_template_layouts, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :csat_surveys, class_name: "Csat::Survey", dependent: :destroy
  has_many :csat_survey_responses, class_name: "Csat::SurveyResponse", dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :filters, dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :sla_policies, dependent: :destroy
  has_many :conversation_slas, dependent: :destroy
  has_many :business_hour_groups, dependent: :destroy
  has_many :business_hours, dependent: :destroy
  has_many :assignment_policies, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :user_skills, dependent: :destroy
  has_many :chat_bots, dependent: :destroy
  has_one :ai_wallet, class_name: "Ai::Wallet", dependent: :destroy
  has_many :ai_agents, class_name: "Ai::Agent", dependent: :destroy
  has_many :webhook_deliveries, class_name: "Webhook::Delivery", dependent: :destroy

  after_create :generate_default_roles
  after_create :generate_default_custom_fields
  after_create :create_default_ai_wallet

  def display_name
    name
  end

  def event_payload
    {
      id: id,
      name: name,
      type: "Account"
    }
  end

  # --- Deletable Lifecycle Hooks ---

  def after_deactivate_for_deletion
    access_tokens.delete_all
    domains.update_all(status: :inactive)
    active_subscription&.cancel!(immediate: true)
    account_users.update_all(status: AccountUser.statuses[:pending_deletion])
  end

  CHANNEL_CLASSES = [
    Channel::Email,
    Channel::WebWidget,
    Channel::MobileWidget,
    Channel::ContactForm,
    Channel::FacebookPage,
    Channel::Instagram,
    Channel::Whatsapp,
    Channel::Custom,
    Channel::ShortMessage
  ].freeze

  def after_mark_as_deleted
    account_users.update_all(status: AccountUser.statuses[:deleted])
    with_shard do
      CHANNEL_CLASSES.each do |channel_class|
        channel_class.where(account_id: id).destroy_all if channel_class.table_exists?
      end
      inboxes.destroy_all
    end
  end

  def after_restore_active
    domains.update_all(status: :active)
    account_users.update_all(status: AccountUser.statuses[:active])
  end

  private

  def generate_default_roles
    Access::RoleGenerator.call(self)
  end

  def generate_default_custom_fields
    Accounts::DefaultCustomFieldsCreator.call(account: self)
  end

  def create_default_ai_wallet
    create_ai_wallet!(balance: 0)
  end
end

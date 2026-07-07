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
  include CodeGenerator.new(prefix: "ACC", column: :identifier)
  include CodeGenerator.new(prefix: "REF", column: :referral_code)
  include Addressable
  include Billable
  include LimitEnforceable
  include ShardResolvable

  def users_count
    current_usage(:users)
  end
  def feature_enabled?(feature)
    base_feature = feature.to_s.delete_suffix("_enabled")
    current_plan&.feature_enabled?(base_feature) == true
  end

  enum :status, { active: 0 }
  enum :referral_commission_type, { fixed: 0 }

  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.keys.map { |k| ActiveSupport::TimeZone[k].name } }

  # Primary DB Associations
  has_many :access_tokens, as: :owner, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :account_invitations, dependent: :destroy
  has_many :domains, dependent: :destroy

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
  has_many :roles, class_name: "Access::Role", dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :email_template_layouts, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :csat_surveys, class_name: "Csat::Survey", dependent: :destroy
  has_many :csat_survey_responses, class_name: "Csat::SurveyResponse", dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :filters, dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :sla_policies, dependent: :destroy
  has_many :conversation_slas, dependent: :destroy
  has_many :notification_subscriptions, dependent: :destroy
  has_many :business_hour_groups, dependent: :destroy
  has_many :business_hours, dependent: :destroy
  has_many :assignment_policies, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :user_skills, dependent: :destroy
  has_many :chat_bots, dependent: :destroy
  has_many :webhook_deliveries, dependent: :destroy

  after_create :generate_default_roles
  after_create :generate_default_custom_fields

  def event_payload
    {
      id: id,
      name: name,
      type: "Account"
    }
  end

  private

  def generate_default_roles
    Access::RoleGenerator.call(self)
  end

  def generate_default_custom_fields
    Accounts::DefaultCustomFieldsCreator.call(account: self)
  end
end

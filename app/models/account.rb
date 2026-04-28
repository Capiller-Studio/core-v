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
  include CodeGenerator.new(prefix: "ACC", referral: true)
  include Addressable
  include Billable
  include LimitEnforceable
  include FlagShihTzu

  has_flags 1 => :api_access,
            2 => :sla,
            3 => :audit_logs,
            4 => :teams,
            5 => :automations,
            6 => :csat,
            7 => :custom_branding,
            column: "features"

  def feature_enabled?(feature)
    # 1. Check if manually enabled via bitmask (overrides/enterprise overrides)
    return true if send("#{feature}?")
    
    # 2. Fallback to the current plan's configuration
    current_plan&.feature_enabled?(feature) == true
  end

  enum :status, { active: 0 }
  enum :referral_commission_type, { fixed: 0 }

  has_many :customers, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :roles, class_name: "Access::Role", dependent: :destroy
  has_many :identity_sources, dependent: :destroy
  has_many :identities, dependent: :destroy
  
  has_many :inboxes, dependent: :destroy
  has_many :portals, class_name: "HelpCenter::Portal", dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :canned_responses, dependent: :destroy
  has_many :macros, dependent: :destroy
  has_many :integrations, dependent: :destroy

  after_create :generate_default_roles

  private

  def generate_default_roles
    Access::RoleGenerator.call(self)
  end
end

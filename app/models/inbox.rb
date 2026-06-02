# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                     :uuid             not null, primary key
#  channel_type           :string           not null
#  configurations         :jsonb            not null
#  default_locale         :string           default("en"), not null
#  display_name           :string
#  flags                  :integer          default(0), not null
#  name                   :string           default(""), not null
#  status                 :integer          default("active"), not null
#  timezone               :string           default("UTC"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#  business_hour_group_id :uuid
#  channel_id             :uuid             not null
#
# Indexes
#
#  index_inboxes_on_account_id                 (account_id)
#  index_inboxes_on_account_id_and_created_at  (account_id,created_at)
#  index_inboxes_on_account_id_and_name        (account_id,name)
#  index_inboxes_on_account_id_and_status      (account_id,status)
#  index_inboxes_on_business_hour_group_id     (business_hour_group_id)
#  index_inboxes_on_channel                    (channel_type,channel_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_hour_group_id => business_hour_groups.id) ON DELETE => nullify
#
class Inbox < ShardRecord
  include FlagShihTzu

  belongs_to :channel, polymorphic: true
  belongs_to :account
  belongs_to :csat_survey, class_name: 'Csat::Survey', optional: true
  belongs_to :conversation_reply_template, class_name: 'EmailTemplate', optional: true
  # belongs_to :address

  has_flags 1 => :csat_survey_enabled, column: 'flags'

  enum :status, { active: 0 }

  has_many :conversations, dependent: :destroy
  has_many :customer_inboxes, dependent: :destroy
  has_many :inbox_users, dependent: :destroy
  has_many :users, through: :inbox_users, disable_joins: true
  has_many :inbox_teams, dependent: :destroy
  has_many :teams, through: :inbox_teams
  has_many :customers, through: :customer_inboxes
  has_many :sla_inboxes, dependent: :destroy
  has_many :sla_policies, through: :sla_inboxes
  has_many :assignment_policy_inboxes, dependent: :destroy
  has_many :assignment_policies, through: :assignment_policy_inboxes

  after_destroy :cleanup_integration_settings

  scope :current_inboxes, ->(current_user) { joins(:inbox_users).where(inbox_users: { user: current_user }) }

  def auto_assign?
    configurations.fetch("auto_assign", true)
  end

  before_create :set_primary_inbox_if_first

  private

  def set_primary_inbox_if_first
    self.primary_inbox = true if channel.present? && channel.inboxes.empty?
  end
  def cleanup_integration_settings
    Integration.where("settings @> ?", { subscribed_inboxes: [ id ] }.to_json).find_each do |integration|
      remaining_inboxes = integration.subscribed_inboxes - [ id ]
      integration.update!(settings: integration.settings.merge("subscribed_inboxes" => remaining_inboxes))
    end
  end
end

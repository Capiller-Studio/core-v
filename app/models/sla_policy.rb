# frozen_string_literal: true

# == Schema Information
#
# Table name: sla_policies
#
#  id                          :uuid             not null, primary key
#  configurations              :jsonb            not null
#  description                 :text
#  during_working_hours        :boolean          default(FALSE), not null
#  initial_response_time_limit :float
#  name                        :string           not null
#  resolution_time_limit       :float
#  response_time_limit         :float
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :uuid             not null
#
# Indexes
#
#  index_sla_policies_on_account_id                 (account_id)
#  index_sla_policies_on_account_id_and_created_at  (account_id,created_at)
#  index_sla_policies_on_account_id_and_name        (account_id,name)
#
class SlaPolicy < ShardRecord
  include UsageTrackable

  belongs_to :account
  belongs_to :business_hour_group, optional: true

  has_many :sla_inboxes, dependent: :destroy
  has_many :inboxes, through: :sla_inboxes
  has_many :conversation_slas, dependent: :destroy
  has_many :conversations, through: :conversation_slas
  validates :name, presence: true

  tracks_usage :sla_policies
end

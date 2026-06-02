# frozen_string_literal: true

# == Schema Information
#
# Table name: csat_survey_responses
#
#  id              :uuid             not null, primary key
#  content   :text
#  rating          :integer
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#  conversation_id :uuid             not null
#  customer_id     :uuid             not null
#  message_id      :uuid
#
class Csat::SurveyResponse < ShardRecord
  include Routable

  belongs_to :account
  belongs_to :conversation
  belongs_to :customer
  belongs_to :message, optional: true
  belongs_to :csat_survey, class_name: 'Csat::Survey', optional: true

  enum :status, { pending: 0, submitted: 1 }

  validates :rating, inclusion: { in: 1..5 }, allow_nil: true

  def routing_identifier
    # Prefixing with account_id guarantees absolute cross-shard uniqueness
    # preventing GlobalRouting unique index collision for identical UUIDs
    "#{account_id}_#{id}"
  end
end

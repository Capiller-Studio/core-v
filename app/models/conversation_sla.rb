# frozen_string_literal: true

# == Schema Information
#
# Table name: conversation_slas
#
#  id              :uuid             not null, primary key
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#  conversation_id :uuid             not null
#  sla_policy_id   :uuid             not null
#
# Indexes
#
#  index_conversation_slas_on_account_id                         (account_id)
#  index_conversation_slas_on_account_id_and_created_at          (account_id,created_at)
#  index_conversation_slas_on_account_id_and_status              (account_id,status)
#  index_conversation_slas_on_conversation_id                    (conversation_id)
#  index_conversation_slas_on_conversation_id_and_sla_policy_id  (conversation_id,sla_policy_id) UNIQUE
#  index_conversation_slas_on_sla_policy_id                      (sla_policy_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (sla_policy_id => sla_policies.id) ON DELETE => cascade
#
class ConversationSla < ShardRecord
  belongs_to :account
  belongs_to :sla_policy
  belongs_to :conversation

  enum :status, { pending: 0, successful: 1, failed: 2 }

  scope :active, -> { where(status: :pending) }
  scope :breached, -> { where(status: :failed) }

  # Check if any SLA threshold has been breached
  def sla_breached?
    initial_response_breached? || response_breached? || resolution_breached?
  end

  def mark_as_breached!
    update!(status: :failed)
  end

  def mark_as_successful!
    update!(status: :successful)
  end

  private

  # Time elapsed since conversation was created (in seconds)
  def elapsed_time
    @elapsed_time ||= Time.current - conversation.created_at
  end

  # Time since last agent response (in seconds)
  def time_since_last_response
    last_outgoing = conversation.messages.where(sender_type: "User").order(created_at: :desc).first
    return elapsed_time unless last_outgoing

    Time.current - last_outgoing.created_at
  end

  def initial_response_breached?
    limit = sla_policy.initial_response_time_limit
    return false unless limit

    conversation.first_respond_at.blank? && elapsed_time > limit
  end

  def response_breached?
    limit = sla_policy.response_time_limit
    return false unless limit

    # Only check if there are unanswered customer messages
    last_message = conversation.messages.order(created_at: :desc).first
    return false unless last_message&.sender_type == "Customer"

    time_since_last_response > limit
  end

  def resolution_breached?
    limit = sla_policy.resolution_time_limit
    return false unless limit

    !conversation.resolved? && !conversation.closed? && elapsed_time > limit
  end
end

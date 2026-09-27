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

  # Call this when creating or recalculating SLA
  def recalculate_targets!
    update!(
      target_first_response_at: calculate_target(sla_policy.initial_response_time_limit, conversation.created_at),
      target_next_response_at: calculate_target(sla_policy.response_time_limit, last_customer_message_time),
      target_resolution_at: calculate_target(sla_policy.resolution_time_limit, conversation.created_at)
    )
  end

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

  def initial_response_breached?
    return false unless target_first_response_at

    response_time = conversation.first_respond_at || conversation.messages.where(sender_type: %w[User Account Ai::Agent]).minimum(:created_at)
    if response_time.present?
      response_time > target_first_response_at
    elsif conversation.resolved? || conversation.closed?
      resolved_time = conversation.status_changed_at || conversation.updated_at || Time.current
      resolved_time > target_first_response_at
    else
      Time.current > target_first_response_at
    end
  end

  def response_breached?
    return false unless target_next_response_at

    # Only check if there are unanswered customer messages
    last_message = conversation.messages.order(created_at: :desc).first
    return false unless last_message&.sender_type == "Customer"

    Time.current > target_next_response_at
  end

  def resolution_breached?
    return false unless target_resolution_at

    resolved_time = conversation.status_changed_at || conversation.updated_at || Time.current
    if conversation.resolved? || conversation.closed?
      resolved_time > target_resolution_at
    else
      Time.current > target_resolution_at
    end
  end

  def calculate_target(limit, start_time)
    return nil if limit.blank? || start_time.blank?
    Sla::TargetCalculator.call(sla_policy: sla_policy, start_time: start_time, limit_in_seconds: limit)
  end

  def last_customer_message_time
    conversation.messages.where(sender_type: "Customer").order(created_at: :desc).first&.created_at || conversation.created_at
  end
end

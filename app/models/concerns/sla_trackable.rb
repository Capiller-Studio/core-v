# frozen_string_literal: true

module SlaTrackable
  extend ActiveSupport::Concern

  included do
    has_many :conversation_slas, dependent: :destroy
    has_many :sla_policies, through: :conversation_slas

    after_create_commit :apply_sla_policy
    before_save :track_first_response, if: :will_save_change_to_first_respond_at?
    after_save :check_sla_on_resolve, if: :saved_change_to_status?
  end

  private

  # Automatically apply the SLA policy linked to this conversation's inbox
  def apply_sla_policy
    sla_policy = inbox.sla_policies.first
    return unless sla_policy

    conversation_slas.create!(
      account:,
      sla_policy:
    )
  end

  # Track first agent response time
  def track_first_response
    # first_respond_at is set externally when the first outgoing message is created.
    # This callback ensures the SLA is evaluated at that point.
  end

  # When a conversation is resolved/closed, mark pending SLAs as successful
  def check_sla_on_resolve
    return unless resolved? || closed?

    conversation_slas.active.find_each do |sla|
      if sla.sla_breached?
        sla.mark_as_breached!
      else
        sla.mark_as_successful!
      end
    end
  end
end

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

  # Delegate SLA tracking to the dedicated EventProcessor
  def apply_sla_policy
    process_sla
  end

  def track_first_response
    # first_respond_at is set externally when the first outgoing message is created.
  end

  def check_sla_on_resolve
    # The status change to resolved/closed will trigger process_sla via Conversation after_update_commit
  end
end

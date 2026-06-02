# frozen_string_literal: true

module Sla
  class EventProcessor < ApplicationService
    attr_reader :conversation

    def initialize(conversation:)
      @conversation = conversation
    end

    def call
      # Once a conversation is resolved or closed, SLAs stop tracking.
      if conversation.resolved? || conversation.closed?
        conversation.conversation_slas.active.each(&:mark_as_successful!)
        return
      end

      policy = find_applicable_policy
      return unless policy

      sla = ConversationSla.find_or_initialize_by(
        conversation: conversation,
        sla_policy: policy,
        account: conversation.account
      )
      
      sla.status = :pending unless sla.failed?
      sla.save!
      
      sla.recalculate_targets!
    end

    private

    def find_applicable_policy
      # Simple matching: First SLA policy associated with the conversation's inbox
      conversation.account.sla_policies
                  .joins(:sla_inboxes)
                  .where(sla_inboxes: { inbox_id: conversation.inbox_id })
                  .first
    end
  end
end

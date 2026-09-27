# frozen_string_literal: true

module Sla
  class EventProcessor < ApplicationService
    attr_reader :conversation

    def initialize(conversation:)
      @conversation = conversation
    end

    def call
      # Once a conversation is resolved or closed, evaluate final status for active SLAs.
      if conversation.resolved? || conversation.closed?
        conversation.conversation_slas.active.find_each do |sla|
          if sla.sla_breached?
            sla.mark_as_breached!
          else
            sla.mark_as_successful!
          end
        end
        return
      end

      policies = find_applicable_policies
      return if policies.empty?

      policies.find_each do |policy|
        sla = ConversationSla.find_or_initialize_by(
          conversation: conversation,
          sla_policy: policy,
          account: conversation.account
        )

        next if sla.failed?

        if sla.sla_breached?
          sla.mark_as_breached!
        else
          sla.status = :pending
          sla.save!
          sla.recalculate_targets!
        end
      end
    end

    private

    def find_applicable_policies
      # Policies explicitly attached to this inbox
      inbox_policies = conversation.account.sla_policies
                                   .joins(:sla_inboxes)
                                   .where(sla_inboxes: { inbox_id: conversation.inbox_id })

      return inbox_policies if inbox_policies.exists?

      # Fallback to global policies (policies with no specific inbox assigned)
      conversation.account.sla_policies.where.missing(:sla_inboxes)
    end
  end
end

# frozen_string_literal: true

module Sla
  class EventProcessorWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform(conversation_id)
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation

      # Shard handling is required if conversations are on a separate DB,
      # but since this worker acts on a conversation, we should ensure context is set.
      # Deskbolic models like Conversation inherit from ShardRecord, so usually finding it is enough.
      # However, let's wrap in with_shard just in case the Sla tools require it.
      conversation.account.with_shard do
        Sla::EventProcessor.call(conversation: conversation)
      end
    end
  end
end

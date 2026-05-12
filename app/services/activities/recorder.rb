# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Activities
  class Recorder < ApplicationService
    attr_reader :trackable, :event_type, :changes, :actor, :account, :snapshot

    def initialize(trackable:, event_type:, changes: {}, actor: nil)
      @trackable  = trackable
      @event_type = event_type
      @actor      = actor || Current.user
      @account    = trackable.try(:account) || trackable.try(:inbox).try(:account)
      
      # Deep synchronous capture to eliminate race conditions during async workers
      @changes    = changes.presence || (trackable.respond_to?(:changes_payload) ? trackable.changes_payload : {})
      @snapshot   = trackable.respond_to?(:snapshot_payload) ? trackable.snapshot_payload : trackable.attributes
    end

    def call
      return unless account

      # Offload to background worker for performance, passing the pre-captured snapshot
      ActivityLogWorker.perform_async(
        account.id,
        trackable_type: trackable.class.name,
        trackable_id: trackable.id,
        event_type: event_type,
        actor_type: actor&.class&.name,
        actor_id: actor&.id,
        changes: changes,
        snapshot: snapshot,
        metadata: request_metadata
      )
    end

    private

    def request_metadata
      {
        remote_ip:  Current.ip_address,
        user_agent: Current.user_agent,
        request_id: Current.request_id
      }.compact
    end
  end
end

# frozen_string_literal: true

class SlaCheckWorker
  include Sidekiq::Worker

  # Run periodically via cron (e.g., every 30 minutes) to check pending SLAs for breaches

  def perform
    time_now = Time.current

    active_shards = Account.distinct.pluck(:shard_key)

    active_shards.each do |shard_key|
      begin
        ShardRecord.connected_to(shard: shard_key.to_sym, role: :writing) do
          # Find SLAs where any of the targets have passed
          breached_slas = ConversationSla.active.where(
            "target_first_response_at < :now OR target_next_response_at < :now OR target_resolution_at < :now",
            now: time_now
          ).includes(:conversation, :sla_policy)

          breached_slas.find_each do |sla|
            next unless sla.sla_breached?

            sla.mark_as_breached!
            notify_breach(sla)
          end
        end
      rescue StandardError => e
        Rails.logger.error("SlaCheckWorker failed on shard #{shard_key}: #{e.message}")
        SystemLogs::Logger.call(
          event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
          level: :error,
          message: "SlaCheckWorker failed on shard #{shard_key}: #{e.message}",
          payload: {
            worker: "SlaCheckWorker",
            shard_key: shard_key,
            error: e.message,
            backtrace: e.backtrace&.first(10)
          }
        )
      end
    end
  end

  private

  def notify_breach(sla)
    conversation = sla.conversation
    assignee = conversation.assignee

    # Notify the assigned agent if there is one
    if assignee
      Notification.create!(
        account: conversation.account,
        user: assignee,
        resource: conversation,
        event: :sla_breached
      )
    end

    # Also notify account owners
    admin_ids = AccountUser.where(
      account: conversation.account,
      owner: true
    ).pluck(:user_id)

    inbox_admin_ids = conversation.inbox.inbox_users
                                 .where(user_id: admin_ids)
                                 .where.not(user_id: assignee&.id)
                                 .pluck(:user_id)

    inbox_admin_ids.each do |user_id|
      Notification.create!(
        account: conversation.account,
        user_id:,
        resource: conversation,
        event: :sla_breached
      )
    end
  end
end

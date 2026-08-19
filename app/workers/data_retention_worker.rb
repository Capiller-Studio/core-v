# frozen_string_literal: true

# TODO: Data retention pruning is temporarily disabled for initial product launch.
# We will enable this worker several months post-launch once customer usage metrics stabilize.
class DataRetentionWorker
  include Sidekiq::Worker
  sidekiq_options queue: "maintenance", retry: 3

  # Safety grace period added on top of the plan retention period (6 months buffer)
  RETENTION_BUFFER = 6.months

  def perform
    # Disabled for initial launch phase — early return
    return

    Account.find_each do |account|
      process_account_retention(account)
    rescue StandardError => e
      Rails.logger.error("[DataRetentionWorker] Failed for Account ##{account.id}: #{e.message}")
    end
  end

  private

  def process_account_retention(account)
    plan = account.current_plan
    return unless plan

    retention_months = plan.limit_for("data_retention_months")
    return if retention_months == -1 || retention_months.to_i <= 0

    cutoff_date = (retention_months.to_i.months + RETENTION_BUFFER).ago

    account.with_shard do
      # 1. Identify and delete messages older than retention cutoff + buffer
      old_messages = account.messages.where(created_at: ...cutoff_date)
      affected_conversation_ids = old_messages.distinct.pluck(:conversation_id)

      deleted_messages_count = 0
      old_messages.find_each do |message|
        message.destroy
        deleted_messages_count += 1
      end

      # 2. Check affected conversations and only delete those that are now completely empty
      deleted_conversations_count = 0
      if affected_conversation_ids.present?
        account.conversations.where(id: affected_conversation_ids).where.missing(:messages).find_each do |conversation|
          conversation.destroy
          deleted_conversations_count += 1
        end
      end

      if deleted_messages_count.positive? || deleted_conversations_count.positive?
        Rails.logger.info(
          "[DataRetentionWorker] Account ##{account.id}: Pruned #{deleted_messages_count} messages " \
          "and #{deleted_conversations_count} empty conversations older than #{retention_months} months (+#{RETENTION_BUFFER.inspect} buffer)."
        )
      end
    end
  end
end

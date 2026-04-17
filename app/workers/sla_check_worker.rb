# frozen_string_literal: true

class SlaCheckWorker
  include Sidekiq::Worker

  # Run periodically via cron (e.g., every 30 minutes) to check pending SLAs for breaches
  # TODO: Configure in scheduled.rb

  def perform
    ConversationSla.active.includes(:sla_policy, conversation: :messages).find_each do |sla|
      next unless sla.sla_breached?

      sla.mark_as_breached!
      notify_breach(sla)
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

    # Also notify inbox agents who are admins/owners
    admin_ids = AccountUser.where(
      account: conversation.account,
      role: [:owner, :admin]
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

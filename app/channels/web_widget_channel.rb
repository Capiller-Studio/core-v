# frozen_string_literal: true

class WebWidgetChannel < ApplicationCable::Channel
  attr_accessor :connection_token

  before_subscribe :configure_connection_token
  before_subscribe :current_subscriber

  def subscribed
    stream_from(connection_token)
    track_activity
  end

  def unsubscribed; end

  def ping
    activity
  end

  def activity
    track_activity
  end

  def typing(data)
    # Broadcast typing indicator to agents watching this conversation
    conversation = current_customer.conversations
                                   .where(inbox_id: customer_inbox&.inbox_id)
                                   .active.last

    return unless conversation

    conversation.users.pluck(:connection_token).each do |token|
      ActionCable.server.broadcast(
        token,
        {
          event: "typing",
          conversation_id: conversation.id,
          sender_type: "Customer",
          sender_id: current_customer.id,
          status: data["status"]
        }
      )
    end
  end

  def read(data = {})
    track_activity
    return unless current_account && current_customer

    current_account.with_shard do
      message_id = data["message_id"]
      if message_id.present?
        msg = Message.find_by(id: message_id, account_id: current_account.id)
        msg.read! if msg && !msg.incoming? && !msg.read?
      end

      conversation_id = data["conversation_id"]
      conversation = if conversation_id.present?
                       current_customer.conversations.find_by(id: conversation_id)
      else
                       current_customer.conversations.where(inbox_id: customer_inbox&.inbox_id).active.last
      end

      if conversation
        unread = conversation.messages.where.not(sender_type: "Customer").where.not(status: :read)
        unread.find_each(&:read!) if unread.exists?
        UnreadCounts::Reset.call(conversation, current_customer)
      end
    end
  end

  private

  def configure_connection_token
    self.connection_token = params[:connection_token]
  end

  def current_subscriber
    @current_subscriber ||= current_customer
  end

  def current_customer
    @current_customer ||= customer_inbox&.customer
  end

  def customer_inbox
    @customer_inbox ||= CustomerInbox.find_by(connection_token: connection_token)
  end

  def current_account
    @current_account ||= current_customer&.account
  end

  def track_activity
    return unless current_account && current_customer

    ::Utilities::ActivityHelpers.update_activity(
      current_account.id,
      "Customer",
      current_customer.id
    )
  end
end

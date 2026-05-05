# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Mailboxes
  class ConversationCreator < ApplicationService
    attr_accessor :mail, :email_channel, :account, :parsed_mail, :inbox, :sender,
                  :conversation

    def initialize(mail:, email_channel:)
      self.mail          = mail
      self.email_channel = email_channel
      self.account       = email_channel.account
    end

    def call
      # TODO: Important -> Use correct shard based on current-account
      self.parsed_mail = ::Parser::MailParser.call(mail:)
      find_inbox

      ActiveRecord::Base.transaction do
        find_or_create_sender
        find_or_create_conversation
        create_message
      end
    end

    private

    def find_inbox
      # TODO: Logic for finding the correct inbox. Maybe: One inbox will act as default and other inboxes will
      # receive conversations/messages based on Filters
      self.inbox = email_channel.inboxes.first
    end

    def find_or_create_conversation
      find_conversation || create_conversation
      find_or_create_conversation_memeber
    end

    def find_conversation
      find_conversation_by_uuid || find_conversation_by_in_reply_to || find_conversation_by_references
    end

    # Strategy 1: reply+<uuid>@domain address pattern
    def find_conversation_by_uuid
      uuid = parsed_mail.reply_to_conversation_uuid
      return unless uuid

      self.conversation = account.conversations.find_by(identifier: uuid)
    end

    # Strategy 2: In-Reply-To header matching an existing message's external_id
    def find_conversation_by_in_reply_to
      return if parsed_mail.in_reply_to.blank?

      message = account.messages.find_by(external_id: parsed_mail.in_reply_to)
      self.conversation = message&.conversation
    end

    # Strategy 3: References header — walk through to find any matching message
    def find_conversation_by_references
      return if parsed_mail.references.blank?

      parsed_mail.references.find_each do |ref|
        message = account.messages.find_by(external_id: ref)
        if message
          self.conversation = message.conversation
          return conversation
        end
      end
      nil
    end

    def create_conversation
      # identifier is a UUID embedded in outbound reply-to address: reply+<identifier>@domain
      # This allows customers to reply and have it routed back to this conversation.
      self.conversation = account.conversations.create!(
        inbox:,
        source: :email,
        identifier: SecureRandom.uuid,
        data: {
          email: {
            subject: parsed_mail.subject,
            message_id: parsed_mail.message_id,
            in_reply_to: parsed_mail.in_reply_to,
            from: parsed_mail.from,
            to: parsed_mail.receiver
          }
        }
      )
    end

    def find_or_create_sender
      find_user || find_customer || create_customer
    end

    def find_user
      self.sender = inbox.users.find_by(email: parsed_mail.original_sender.downcase)
    end

    def find_or_create_customer
      find_customer || create_customer
    end

    def find_customer
      self.sender = inbox.customers.find_by(email: parsed_mail.original_sender.downcase)
    end

    def create_customer
      self.sender = Customers::CustomerCreator.call(
        account:,
        inbox:,
        external_id: parsed_mail.original_sender,
        email: parsed_mail.original_sender,
        params: {
          name: find_customer_name,
          avatar_url: generate_gravatar_url(parsed_mail.original_sender),
          data: {
            email: { message_id: mail.message_id }
          }
        }
      )
    end

    def generate_gravatar_url(email)
      return if email.blank?
      hash = Digest::MD5.hexdigest(email.downcase.strip)
      "https://www.gravatar.com/avatar/#{hash}?d=404"
    end

    def find_customer_name
      parsed_mail.sender_name.presence || parsed_mail.from.first.split("@").first
    end

    def find_or_create_conversation_memeber
      conversation.conversation_members.find_or_create_by!(conversation:, member: sender, account:)
    end

    def create_message
      MessageCreator.call(
        account:,
        inbox:,
        conversation:,
        mail:,
        parsed_mail:,
        sender:
      )
    end
  end
end

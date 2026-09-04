# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Messages
  class MessageCreator < ApplicationService
    attr_accessor :conversation, :account, :sender, :content, :attachments,
                  :visibility, :reply_to_message_id, :source

    def initialize(conversation:, content: nil, attachments: nil, sender: nil, visibility: "global", reply_to_message_id: nil, source: nil)
      self.conversation         = conversation
      self.account              = conversation.account
      self.sender               = sender
      self.content              = content.presence
      self.attachments          = Array(attachments).compact_blank
      self.visibility           = visibility == "personal" ? "personal" : "global"
      self.reply_to_message_id  = reply_to_message_id
      self.source               = source || conversation.source
    end

    def call
      return [] if content.blank? && attachments.blank?

      account.with_shard do
        messages = ShardRecord.transaction do
          if split_required?
            create_split_messages
          else
            create_unified_message
          end
        end

        enqueue_deliveries(messages)
        messages
      end
    end

    private

    def channel
      @channel ||= conversation.outbound_channel || conversation.inbox&.channel
    end

    def split_required?
      return false unless visibility == "global"
      return false if attachments.blank?

      case channel
      when Channel::FacebookPage, Channel::Instagram
        content.present? || attachments.size > 1
      when Channel::Whatsapp
        if attachments.size > 1
          true
        elsif content.present? && attachments.one?
          !captionable_attachment?(attachments.first)
        else
          false
        end
      else
        false
      end
    end

    def create_unified_message
      msg = build_message(content: content)
      msg.save!
      attach_files(msg, attachments)
      [msg]
    end

    def create_split_messages
      case channel
      when Channel::FacebookPage, Channel::Instagram
        create_facebook_or_instagram_split_messages
      when Channel::Whatsapp
        create_whatsapp_split_messages
      else
        create_unified_message
      end
    end

    def create_facebook_or_instagram_split_messages
      messages = []

      # 1. Text message (if present)
      if content.present?
        text_msg = build_message(content: content)
        text_msg.save!
        messages << text_msg
      end

      # 2. Each attachment as an individual message
      attachments.each do |file|
        att_msg = build_message(content: nil)
        att_msg.save!
        attach_files(att_msg, [file])
        messages << att_msg
      end

      messages
    end

    def create_whatsapp_split_messages
      messages = []
      remaining_attachments = attachments.dup

      if content.present?
        captionable_idx = remaining_attachments.find_index { |f| captionable_attachment?(f) }

        if captionable_idx
          captioned_file = remaining_attachments.delete_at(captionable_idx)
          primary_msg = build_message(content: content)
          primary_msg.save!
          attach_files(primary_msg, [captioned_file])
          messages << primary_msg
        else
          text_msg = build_message(content: content)
          text_msg.save!
          messages << text_msg
        end
      else
        first_file = remaining_attachments.shift
        first_msg = build_message(content: nil)
        first_msg.save!
        attach_files(first_msg, [first_file])
        messages << first_msg
      end

      remaining_attachments.each do |file|
        sibling_msg = build_message(content: nil)
        sibling_msg.save!
        attach_files(sibling_msg, [file])
        messages << sibling_msg
      end

      messages
    end

    def build_message(content:)
      conversation.messages.build(
        account: account,
        inbox: conversation.inbox,
        sender: sender,
        source: source,
        visibility: visibility,
        content: content,
        reply_to_message_id: reply_to_message_id
      )
    end

    def attach_files(target_message, files)
      files.each do |file|
        if file.is_a?(Attachment)
          file.update!(resource: target_message)
        else
          target_message.attachments.create!(
            account: account,
            file: file,
            attachment_type: detect_attachment_type(file)
          )
        end
      end
    end

    def enqueue_deliveries(messages)
      return unless visibility == "global"
      return if messages.empty?

      if messages.size == 1
        Messages::DeliveryWorker.perform_async(account.id, messages.first.id)
      else
        Messages::DeliveryWorker.perform_async(account.id, messages.map(&:id))
      end
    end

    def detect_attachment_type(file)
      return file.attachment_type if file.is_a?(Attachment)

      content_type = file.content_type.to_s if file.respond_to?(:content_type)
      content_type = Rack::Mime.mime_type(File.extname(file.path), "") if content_type.blank? && file.respond_to?(:path) && file.path.present?
      content_type ||= ""

      case content_type
      when %r{\Aimage/} then :image
      when %r{\Avideo/} then :video
      when %r{\Aaudio/} then :audio
      else :file
      end
    end

    def captionable_attachment?(file)
      type = detect_attachment_type(file).to_sym
      %i[image video file].include?(type)
    end
  end
end

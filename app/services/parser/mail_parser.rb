# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Parser
  class MailParser < ApplicationService
    include ::Utilities::StringHelpers

    ALLOWED_TAGS = %w[
      a b blockquote br code div em h1 h2 h3 h4 h5 h6 hr i img li ol p pre
      span strong table tbody td tfoot th thead tr u ul
    ].freeze

    ALLOWED_ATTRIBUTES = %w[
      alt class colspan href rowspan src title width height style target
    ].freeze

    attr_accessor :mail

    def initialize(mail:)
      self.mail = mail
    end

    def call
      self
    end

    def subject
      @subject ||= change_encoding(mail.subject)
    end

    def attachments
      @attachments ||= mail.attachments.map do |attachment|
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(attachment.body.to_s),
          filename: attachment.filename,
          content_type: attachment.content_type
        )
        { original: attachment, blob: }
      end
    end

    def from
      @from ||= (mail.from.to_a + mail.reply_to.to_a).map(&:downcase)
    end

    def sender_name
      @sender_name ||= Mail::Address.new((mail[:reply_to] || @mail[:from]).value).name
    end

    def original_sender
      @original_sender ||=
        address(mail[:reply_to].try(:value)) || mail["X-Original-Sender"].try(:value) || address(from.first)
    end

    def address(email)
      Mail::Address.new(email).address
    end

    def forwarded_for
      @forwarded_for ||= mail["X-Forwarded-For"].try(:value)
    end

    def receiver
      @receiver ||= mail.to.to_a + Array(forwarded_for)
    end

    def message_id
      @message_id ||= mail.message_id
    end

    def in_reply_to
      @in_reply_to ||= mail.in_reply_to
    end

    def references
      @references ||= Array(mail.references)
    end

    # Extract conversation UUID from reply-to address pattern: reply+<uuid>@domain
    def reply_to_conversation_uuid
      @reply_to_conversation_uuid ||= begin
        all_recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a + [ mail["X-Original-To"]&.value ]
        reply_address = all_recipients.compact.find { |addr| addr.match?(/reply\+[^@]+@/i) }

        reply_address&.match(/reply\+([^@]+)@/i)&.captures&.first
      end
    end

    def reply?
      in_reply_to.present? || references.present? || reply_to_conversation_uuid.present?
    end

    def auto_reply?
      @auto_reply ||= begin
        auto_submitted = mail["Auto-Submitted"]&.value.to_s.downcase
        if (auto_submitted.present? && auto_submitted != "no") ||
           mail["X-Autoreply"]&.value.present? ||
           mail["X-Auto-Response-Suppress"]&.value.present? ||
           (mail["X-PM-Message-Id"]&.value.present? && mail["X-Mailer-Daemon"]&.value.present?) ||
           %w[bulk junk list].include?(mail["Precedence"]&.value.to_s.downcase) ||
           mail["Feedback-ID"]&.value.present? ||
           mail.from&.any? { |addr| addr.match?(/mailer-daemon|postmaster/i) }
          true
        else
          false
        end
      end
    end

    def text_content
      return unless text?

      @text_content ||= begin
        original_content = part_content(mail.text_part) || ""
        parsed_content = original_content

        # return if parsed_content.blank?

        parsed_content
      end
    end

    def text_content_parsed
      @text_content_parsed ||= text_content&.truncate(60_000, omission: '... [Message truncated]')
    end

    def html_content
      return unless html?

      @html_content ||= begin
        original_content = part_content(mail.html_part) || ""
        parsed_content = original_content

        parsed_content
      end
    end

    def html_content_parsed
      @html_content_parsed ||= begin
        return if html_content.blank?

        sanitized_html = Rails::Html::SafeListSanitizer.new.sanitize(
          html_content,
          tags: ALLOWED_TAGS,
          attributes: ALLOWED_ATTRIBUTES
        )
        
        sanitized_html&.truncate(60_000, omission: '... [Message truncated]')
      end
    end

    private

    def html?
      @html ||=
        mail.content_type.to_s.include?("text/html") || mail.html_part&.content_type&.include?("text/html")
    end

    def text?
      @text ||=
        mail.content_type.to_s.include?("text/plain") || mail.text_part&.content_type&.include?("text/plain")
    end

    def multipart?
      @multipart ||=
        mail.content_type.to_s.include?("multipart") || mail.parts.any?
    end

    def part_content(part)
      return unless html? || text?

      decoded = part&.decoded || (!multipart? ? mail.decoded : "")
      change_encoding(decoded)
    end
  end
end

# frozen_string_literal: true

class ContactFormMailer < ApplicationMailer
  # Sends an agent reply to the customer who submitted a contact form.
  #
  # In production, ServicePicker delegates contact form replies to
  # ConversationReplyMailer for unified branding, templates, and SMTP routing.
  # This mailer serves confirmation emails and standalone reply fallback.
  def reply_message(message)
    @message = message
    @conversation = message.conversation
    @customer = @conversation.customers.first
    @account = message.account

    return unless @customer&.email

    @agent_name = @message.sender.try(:display_name).presence || @message.sender.try(:name).presence || "Agent"

    subject = I18n.t("mailers.contact_form.reply.subject", title: @conversation.title, default: "Re: %{title}")

    mail(
      to: @customer.email,
      subject: subject,
      from: from_address,
      reply_to: reply_to_address,
      message_id: "<#{@message.id}@helpbolic.com>",
      in_reply_to: @conversation.data.dig("email", "message_id"),
      references: build_references
    )
  end

  def confirmation_email(conversation)
    @conversation = conversation
    @customer = conversation.customers.first
    @account = conversation.account
    @contact_form = conversation.inbox.channel

    return unless @customer&.email
    return unless @contact_form.send_confirmation_email?

    subject = I18n.t("mailers.contact_form.confirmation.subject", title: @conversation.title, default: "We received your message: %{title}")

    mail(
      to: @customer.email,
      subject: subject,
      from: from_address,
      reply_to: reply_to_address,
      message_id: "<confirmation-#{@conversation.id}@helpbolic.com>"
    )
  end

  private

  # Build a from address using the account name.
  # Uses helpbolic.com relay domain (handled by ApplicationMailer#set_delivery_options)
  # to avoid polluting deskbolic.com sender reputation.
  def from_address
    company_name = @account&.name.presence || "Support"
    display_name = if @agent_name.present? && @agent_name != "Agent"
      "#{@agent_name} from #{company_name}"
    else
      "#{company_name} Support"
    end
    email = resolve_sender_email
    %("#{display_name}" <#{email}>)
  end

  # Resolve sender email: outbound channel email (if custom SMTP), else helpbolic relay
  def resolve_sender_email
    outbound = resolve_outbound_channel
    if outbound.respond_to?(:smtp_enabled?) && outbound.smtp_enabled?
      outbound.email
    elsif outbound.respond_to?(:email) && outbound.email.present?
      outbound.email
    else
      "support@helpbolic.com"
    end
  rescue StandardError
    "support@helpbolic.com"
  end

  # Reply-To address using the reply+<identifier>@<domain> pattern
  # so customer replies are routed back into the conversation by ReplyMailbox.
  def reply_to_address
    return nil unless @conversation

    outbound = resolve_outbound_channel
    domain = if outbound.respond_to?(:forward_email_domain) && outbound.forward_email_domain.present?
      outbound.forward_email_domain
    else
      "#{@conversation.account.identifier.downcase}.helpbolic.com"
    end

    "reply+#{@conversation.identifier}@#{domain}"
  end

  # Build References header for email threading
  def build_references
    return nil unless @conversation

    refs = @conversation.data.dig("email", "references") || []
    original_id = @conversation.data.dig("email", "message_id")
    list = [original_id, *refs].compact
    list.uniq!
    list.join(" ").presence
  end

  # Resolve the outbound channel for this contact form conversation.
  # Priority:
  #   1. Conversation-level outbound_channel (set at creation time)
  #   2. Contact form channel's configured outbound_channel
  #   (No random fallback — defaults to NullChannel which uses helpbolic.com relay)
  def resolve_outbound_channel
    @_outbound ||= begin
      conv_outbound = @conversation&.try(:outbound_channel)
      return conv_outbound if conv_outbound.present?

      channel = @conversation&.inbox&.channel
      form_outbound = channel.try(:outbound_channel) if channel.is_a?(Channel::ContactForm)
      return form_outbound if form_outbound.present?

      nil
    end || NullChannel.new
  end

  # Null object to avoid nil checks on channel methods
  class NullChannel
    def email; nil; end
    def smtp_enabled?; false; end
    def forward_email_domain; nil; end
    def respond_to?(method, include_private = false)
      %i[email smtp_enabled? forward_email_domain].include?(method) || super
    end
  end
end

# frozen_string_literal: true

class ContactFormMailer < ApplicationMailer
  def reply_message(message)
    @message = message
    @conversation = message.conversation
    @customer = @conversation.customers.first
    @account = message.account

    return unless @customer&.email

    subject = I18n.t("mailers.contact_form.reply.subject", title: @conversation.title, default: "Re: %{title}")

    mail(
      to: @customer.email,
      subject: subject,
      from: "#{@account.name} Support <support@deskbolic.com>" # TODO: Use account's configured outbound email
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
      from: "#{@account.name} Support <support@deskbolic.com>"
    )
  end
end

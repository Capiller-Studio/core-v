# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
class OutreachMailer < ActionMailer::Base
  # rubocop:enable Rails/ApplicationMailer
  default from: -> { ENV.fetch("OUTREACH_FROM_EMAIL", "Ahsan from Capiller Rely <ahsan@techbolic.com>") }
  default reply_to: -> { ENV.fetch("OUTREACH_REPLY_TO", "ahsan@techbolic.com") }

  after_action :set_delivery_options

  # outreach(to:, name: nil, company: nil, competitor: nil, custom_hook: nil)
  def outreach(to:, name: nil, company: nil, competitor: nil, custom_hook: nil)
    @recipient_email = to.to_s.strip
    @name = name.presence&.strip
    @company = company.presence&.strip
    @competitor = competitor.to_s.downcase.strip.presence
    @competitor_name = competitor_display_name
    @custom_hook = custom_hook.presence&.strip

    @salutation = @name ? "Hi #{@name}," : "Hi there,"
    @subject = build_subject

    mail(
      to: @recipient_email,
      from: ENV.fetch("OUTREACH_FROM_EMAIL", "Ahsan from Capiller Rely <ahsan@techbolic.com>"),
      reply_to: ENV.fetch("OUTREACH_REPLY_TO", "ahsan@techbolic.com"),
      subject: @subject
    )
  end

  private

  def set_delivery_options
    return if Rails.env.test?

    username = ENV["TECHBOLIC_SMTP_USERNAME"].presence ||
               Rails.application.credentials.dig(:techbolic_smtp, :username) ||
               Rails.application.credentials.techbolic_smtp_username
    password = ENV["TECHBOLIC_SMTP_PASSWORD"].presence ||
               Rails.application.credentials.dig(:techbolic_smtp, :password) ||
               Rails.application.credentials.techbolic_smtp_password

    return unless username.present? && password.present?

    port = ENV.fetch("TECHBOLIC_SMTP_PORT", 587).to_i
    tls = port == 465

    mail.delivery_method(:smtp, {
      address: ENV.fetch("TECHBOLIC_SMTP_ADDRESS", "mail.techbolic.com"),
      port: port,
      domain: ENV.fetch("TECHBOLIC_SMTP_DOMAIN", "techbolic.com"),
      user_name: username,
      password: password,
      authentication: ENV.fetch("TECHBOLIC_SMTP_AUTH", "plain"),
      enable_starttls_auto: !tls,
      tls: tls,
      ssl: tls
    })
  end

  def build_subject
    if @competitor.present?
      comp_name = competitor_display_name
      if @company.present?
        "Quick question regarding #{comp_name} at #{@company}"
      else
        "Rethinking #{comp_name} for your support team?"
      end
    elsif @company.present?
      "Quick question regarding customer support at #{@company}"
    else
      "Modern AI customer support without the $50+/agent price tag"
    end
  end

  def competitor_display_name
    case @competitor.to_s.downcase
    when "helpscout" then "Help Scout"
    when "freshdesk" then "Freshdesk"
    else @competitor.to_s.titleize
    end
  end
end

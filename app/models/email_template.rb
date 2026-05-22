# frozen_string_literal: true

# == Schema Information
#
# Table name: email_templates
#
#  id                       :uuid             not null, primary key
#  name                     :string
#  status                   :integer          default("inactive"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :uuid             not null
#  email_template_layout_id :uuid
#
class EmailTemplate < ShardRecord
  include Translateable
  include Publishable

  TRANSLATABLE_FIELDS = %i[subject body design compiled_html draft_subject draft_body draft_design].freeze

  # System templates seeded for every account
  CONVERSATION_REPLY = "conversation_reply"
  AGENT_NOTIFICATION = "agent_notification"
  WELCOME_EMAIL      = "welcome_email"
  PASSWORD_RESET     = "password_reset"
  EMAIL_VERIFICATION = "email_verification"
  TEAM_INVITATION    = "team_invitation"

  SYSTEM_TEMPLATES = [
    CONVERSATION_REPLY,
    AGENT_NOTIFICATION,
    WELCOME_EMAIL,
    PASSWORD_RESET,
    EMAIL_VERIFICATION,
    TEAM_INVITATION
  ].freeze

  # Available Liquid variables per template type (object.property pattern).
  # Used by the editor UI to show context-aware variable insertion.
  TEMPLATE_VARIABLES = {
    CONVERSATION_REPLY => {
      "customer" => %w[name email],
      "agent"    => %w[name email],
      "message"  => %w[content],
      "conversation" => %w[subject identifier],
      "inbox"    => %w[name],
      "account"  => %w[name]
    },
    AGENT_NOTIFICATION => {
      "agent"    => %w[name email],
      "event"    => %w[title description],
      "conversation" => %w[identifier],
      "inbox"    => %w[name],
      "account"  => %w[name]
    },
    WELCOME_EMAIL => {
      "user"    => %w[name email],
      "account" => %w[name]
    },
    PASSWORD_RESET => {
      "user"       => %w[name email],
      "reset_link" => []
    },
    EMAIL_VERIFICATION => {
      "user"              => %w[name email],
      "verification_link" => []
    },
    TEAM_INVITATION => {
      "inviter" => %w[name],
      "team"    => %w[name],
      "invite_link" => [],
      "account" => %w[name]
    }
  }.freeze

  belongs_to :account
  belongs_to :email_template_layout, optional: true
  has_many :attachments, as: :resource, dependent: :destroy

  enum :status, { inactive: 0, active: 1 }

  translates(*TRANSLATABLE_FIELDS)

  validates :name, presence: true

  scope :system_templates, -> { where(name: SYSTEM_TEMPLATES) }

  # Render the template body using Liquid with variable interpolation.
  # Always uses the PUBLISHED compiled_html (never draft).
  def render_body(variables = {})
    template_body = compiled_html.presence || body
    return "" if template_body.blank?

    liquid_template = Liquid::Template.parse(template_body)
    liquid_template.render(variables.stringify_keys)
  end

  # Render the template subject using Liquid.
  def render_subject(variables = {})
    template_subject = subject
    return "" if template_subject.blank?

    liquid_template = Liquid::Template.parse(template_subject)
    liquid_template.render(variables.stringify_keys)
  end

  # Find an active, published template for an account.
  def self.for_account(account, name)
    active.find_by(account: account, name: name)
  end

  # Returns the variable groups available for this template type.
  def variable_groups
    TEMPLATE_VARIABLES[name] || {}
  end

  # Fallback to the account's locale if a translation is missing
  def fallback_locale
    account.locale || I18n.default_locale
  end

  private

  # Called by Publishable#publish! to compile MJML → HTML.
  def compile_body(mjml_source)
    layout_body = email_template_layout&.body
    Emails::TemplateCompilerService.compile_with_layout(mjml_source, layout_body: layout_body)
  end
end

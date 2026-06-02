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

  publishable_fields :subject, :body, :design

  TRANSLATABLE_FIELDS = %i[subject body design compiled_html draft_subject draft_body draft_design].freeze

  enum :template_type, {
    conversation_reply: 0,
    agent_notification: 1,
    welcome_email: 2,
    password_reset: 3,
    email_verification: 4,
    team_invitation: 5,
    csat_survey: 6
  }

  SYSTEM_TEMPLATES = template_types.keys.freeze

  TEMPLATE_VARIABLES = {
    "conversation_reply" => {
      "customer" => %w[name email],
      "agent"    => %w[name email],
      "message"  => %w[content],
      "conversation" => %w[subject identifier],
      "inbox"    => %w[name],
      "account"  => %w[name]
    },
    "agent_notification" => {
      "agent"    => %w[name email],
      "event"    => %w[title description],
      "conversation" => %w[identifier],
      "inbox"    => %w[name],
      "account"  => %w[name]
    },
    "welcome_email" => {
      "user"    => %w[name email],
      "account" => %w[name]
    },
    "password_reset" => {
      "user"       => %w[name email],
      "reset_link" => []
    },
    "email_verification" => {
      "user"              => %w[name email],
      "verification_link" => []
    },
    "team_invitation" => {
      "inviter" => %w[name],
      "team"    => %w[name],
      "invite_link" => [],
      "account" => %w[name]
    },
    "csat_survey" => {
      "customer" => %w[name email],
      "agent"    => %w[name email],
      "conversation" => %w[subject identifier],
      "inbox"    => %w[name],
      "account"  => %w[name],
      "csat"     => %w[survey_url]
    }
  }.freeze

  belongs_to :account
  belongs_to :email_template_layout, optional: true
  has_many :attachments, as: :resource, dependent: :destroy

  enum :status, { inactive: 0, active: 1 }

  translates(*TRANSLATABLE_FIELDS)

  validates :name, presence: true
  validates :template_type, presence: true

  before_create :enforce_email_templates_limit!
  after_create_commit :increment_email_templates_usage
  after_destroy_commit :decrement_email_templates_usage

  private

  def enforce_email_templates_limit!
    return if account.within_limit?(:email_templates)

    errors.add(:base, "Email templates limit reached for your plan. Please upgrade.")
    throw(:abort)
  end

  def increment_email_templates_usage
    account.increment_usage!(:email_templates)
  end

  def decrement_email_templates_usage
    account.decrement_usage!(:email_templates)
  end

  public

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
    TEMPLATE_VARIABLES[template_type] || {}
  end

  # Fallback to the account's locale if a translation is missing
  def fallback_locale
    account.locale || I18n.default_locale
  end

  # Model-specific lifecycle callbacks for Publishable concern

  def after_publish_assignments!(locale)
    # Compile MJML → HTML before the record is saved
    layout_body = email_template_layout&.body
    self.compiled_html = Emails::TemplateCompilerService.compile_with_layout(body, layout_body: layout_body)
  end
end

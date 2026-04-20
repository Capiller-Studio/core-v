# frozen_string_literal: true

# == Schema Information
#
# Table name: email_templates
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid             not null
#
# Indexes
#
#  index_email_templates_on_account_id           (account_id)
#  index_email_templates_on_account_id_and_name  (account_id,name)
#
class EmailTemplate < ShardRecord
  include Translateable

  TRANSLATABLE_FIELDS = %i[subject body].freeze

  # Only these two templates are editable by accounts via database
  # All other emails use standard mailer views
  CONVERSATION_REPLY   = "conversation_reply"
  AGENT_NOTIFICATION   = "agent_notification"

  SYSTEM_TEMPLATES = [
    CONVERSATION_REPLY,
    AGENT_NOTIFICATION
  ].freeze

  belongs_to :account
  has_many :attachments, as: :resource, dependent: :destroy

  translates(*TRANSLATABLE_FIELDS)

  scope :system_templates, -> { where(name: SYSTEM_TEMPLATES) }

  # Render the template body using Liquid with variable interpolation
  def render_body(variables = {})
    template_body = body
    return "" if template_body.blank?

    liquid_template = Liquid::Template.parse(template_body)
    liquid_template.render(variables.stringify_keys)
  end

  # Render the template subject using Liquid
  def render_subject(variables = {})
    template_subject = subject
    return "" if template_subject.blank?

    liquid_template = Liquid::Template.parse(template_subject)
    liquid_template.render(variables.stringify_keys)
  end

  # Find template for account, falling back to system default
  def self.for_account(account, name)
    find_by(account:, name:)
  end
end

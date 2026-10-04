# == Schema Information
#
# Table name: csat_surveys
#
#  id                :uuid             not null, primary key
#  account_id        :uuid             not null
#  email_template_id :uuid
#  name              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_csat_surveys_on_account_id         (account_id)
#  index_csat_surveys_on_email_template_id  (email_template_id)
#

# frozen_string_literal: true

class Csat::Survey < ShardRecord
  include Translateable
  include UsageTrackable

  TRANSLATABLE_FIELDS = %i[prompt portal_title portal_subtitle portal_feedback_label].freeze

  belongs_to :account
  belongs_to :email_template, optional: true
  
  has_many :inboxes, foreign_key: :csat_survey_id, dependent: :nullify
  
  translates(*TRANSLATABLE_FIELDS)

  validates :name, presence: true

  tracks_usage :csat_surveys

  # Renders the Liquid template for the channel prompt (e.g., WhatsApp, Widget)
  def render_prompt(variables = {})
    template_prompt = prompt
    return "" if template_prompt.blank?

    liquid_template = Liquid::Template.parse(template_prompt)
    liquid_template.render(variables.deep_stringify_keys)
  end
end

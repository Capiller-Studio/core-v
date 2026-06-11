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

  TRANSLATABLE_FIELDS = %i[prompt portal_title portal_subtitle portal_feedback_label].freeze

  belongs_to :account
  belongs_to :email_template, optional: true
  
  has_many :inboxes, dependent: :nullify
  
  translates(*TRANSLATABLE_FIELDS)

  validates :name, presence: true

  before_create :enforce_csat_surveys_limit!
  after_create_commit :increment_csat_surveys_usage
  after_destroy_commit :decrement_csat_surveys_usage
  # Renders the Liquid template for the channel prompt (e.g., WhatsApp, Widget)
  def render_prompt(variables = {})
    template_prompt = prompt
    return "" if template_prompt.blank?

    liquid_template = Liquid::Template.parse(template_prompt)
    liquid_template.render(variables.stringify_keys)
  end

  private

  def enforce_csat_surveys_limit!
    return if account.within_limit?(:csat_surveys)

    errors.add(:base, "CSAT surveys limit reached for your plan. Please upgrade.")
    throw(:abort)
  end

  def increment_csat_surveys_usage
    account.increment_usage!(:csat_surveys)
  end

  def decrement_csat_surveys_usage
    account.decrement_usage!(:csat_surveys)
  end

  private
end

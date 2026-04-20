# frozen_string_literal: true

# == Schema Information
#
# Table name: email_template_translations
#
#  id                :bigint           not null, primary key
#  body              :text
#  locale            :string           not null
#  subject           :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  email_template_id :uuid             not null
#
# Indexes
#
#  index_email_template_translations_on_email_template_id            (email_template_id)
#  index_email_template_translations_on_email_template_id_and_locale (email_template_id,locale) UNIQUE
#  index_email_template_translations_on_locale                       (locale)
#  index_email_template_translations_on_subject_and_locale           (subject,locale)
#
# Foreign Keys
#
#  fk_rails_...  (email_template_id => email_templates.id) ON DELETE => cascade
#
class EmailTemplateTranslation < ShardRecord
  belongs_to :email_template

  validates :locale, presence: true, uniqueness: { scope: :email_template_id }
  validates :subject, presence: true
  validates :body, presence: true
end

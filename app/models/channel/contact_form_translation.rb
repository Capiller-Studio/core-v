# == Schema Information
#
# Table name: channel_contact_form_translations
#
#  id                      :uuid             not null, primary key
#  channel_contact_form_id :uuid             not null
#  locale                  :string           not null
#  title                   :string
#  subtitle                :string
#  success_message         :string
#  submit_button_text      :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_ccft_on_channel_contact_form_id     (channel_contact_form_id)
#  index_ccft_on_contact_form_id_and_locale  (channel_contact_form_id,locale) UNIQUE
#

# frozen_string_literal: true

module Channel
  class ContactFormTranslation < ShardRecord
    belongs_to :contact_form, class_name: "Channel::ContactForm"

    validates :locale, presence: true
    validates :locale, uniqueness: { scope: :contact_form_id }
  end
end

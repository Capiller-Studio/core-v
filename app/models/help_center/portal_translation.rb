# frozen_string_literal: true
# == Schema Information
#
# Table name: help_center_portal_translations
#
#  id                    :uuid             not null, primary key
#  locale                :string           not null
#  hero_title            :string
#  hero_subtitle         :string
#  search_placeholder    :string
#  header_tagline        :string
#  footer_text           :string
#  contact_page_title    :string
#  contact_page_subtitle :string
#  portal_id             :uuid             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_help_center_portal_translations_on_portal_id             (portal_id)
#  index_help_center_portal_translations_on_portal_id_and_locale  (portal_id,locale) UNIQUE
#

module HelpCenter
  class PortalTranslation < ShardRecord
    belongs_to :portal, class_name: "HelpCenter::Portal"

    validates :locale, presence: true
    validates :portal_id, uniqueness: { scope: :locale }
  end
end

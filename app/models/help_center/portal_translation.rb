# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_portal_translations
#
#  id                    :uuid             not null, primary key
#  contact_page_subtitle :string
#  contact_page_title    :string
#  footer_text           :string
#  header_tagline        :string
#  hero_subtitle         :string
#  hero_title            :string
#  locale                :string           not null
#  search_placeholder    :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  portal_id             :uuid             not null
#
# Indexes
#
#  index_help_center_portal_translations_on_portal_id             (portal_id)
#  index_help_center_portal_translations_on_portal_id_and_locale  (portal_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => help_center_portals.id) ON DELETE => cascade
#
module HelpCenter
  class PortalTranslation < ShardRecord
    belongs_to :portal, class_name: "HelpCenter::Portal"

    validates :locale, presence: true
    validates :portal_id, uniqueness: { scope: :locale }
  end
end

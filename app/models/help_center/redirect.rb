# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_redirects
#
#  id          :uuid             not null, primary key
#  locale      :string
#  source_path :string           not null
#  status_code :integer          default(301), not null
#  target_path :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  portal_id   :uuid             not null
#
# Indexes
#
#  index_help_center_redirects_on_portal_id                                   (portal_id)
#  index_help_center_redirects_on_portal_id_and_source_path_and_locale        (portal_id,source_path,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => help_center_portals.id) ON DELETE => cascade
#
module HelpCenter
  class Redirect < ShardRecord
    belongs_to :portal, class_name: "HelpCenter::Portal"

    validates :source_path, presence: true
    validates :target_path, presence: true
    validates :status_code, inclusion: { in: [301, 302] }

    # locale: nil = applies to all locales; set to a specific locale (e.g. "es") for locale-specific redirects.
    # source_path and target_path store only the slug segment (not the full URL or locale prefix).
    # e.g. source_path: "old-whatsapp-guide", target_path: "setup-whatsapp-channel"
    validates :source_path, uniqueness: { scope: [:portal_id, :locale] }
  end
end

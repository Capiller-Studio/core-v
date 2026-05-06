# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_field_translations
#
#  id              :uuid             not null, primary key
#  description     :text
#  label           :string
#  locale          :string           not null
#  options         :jsonb            not null
#  placeholder     :string
#  created_at      :datetime         not null
#  updated_at     :datetime         not null
#  custom_field_id :uuid             not null
#
# Indexes
#
#  index_custom_field_translations_on_custom_field_id             (custom_field_id)
#  index_custom_field_translations_on_custom_field_id_and_locale  (custom_field_id,locale) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (custom_field_id => custom_fields.id) ON DELETE => cascade
#

class CustomFieldTranslation < ShardRecord
  belongs_to :custom_field

  validates :locale, presence: true
  validates :custom_field_id, uniqueness: { scope: :locale }

  # options jsonb — for select and multi_select field types:
  # Array of option objects. "value" is locale-neutral (always stored on submission);
  # "label" is the localized display string shown in dropdowns/radio lists.
  # Example:
  # [
  #   { "value": "billing",   "label": "Billing" },
  #   { "value": "technical", "label": "Technical Support" },
  #   { "value": Sales",     "label": "Sales" }
  # ]
  # Filtering/querying is always done on the "value" key, never on "label",
  # so queries remain locale-neutral across all translations.
end

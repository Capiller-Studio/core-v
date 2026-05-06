# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_fields
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  entity_type    :integer          default("customer"), not null
#  field_type     :integer          default("text"), not null
#  flags          :integer          default(0), not null
#  key            :string           not null
#  position       :integer
#  required       :boolean          default(FALSE), not null
#  validations    :jsonb            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_custom_fields_on_account_id                    (account_id)
#  index_custom_fields_on_account_id_and_created_at     (account_id,created_at)
#  index_custom_fields_on_account_id_and_entity_type    (account_id,entity_type)
#  index_custom_fields_on_account_id_and_field_type     (account_id,field_type)
#  index_custom_fields_on_account_id_and_key            (account_id,key) UNIQUE
#  index_custom_fields_on_account_id_and_position       (account_id,position)
#

class CustomField < ShardRecord
  include FlagShihTzu
  include Translateable

  belongs_to :account
  has_many :translations, class_name: "CustomFieldTranslation", dependent: :destroy
  has_many :field_resources, class_name: "CustomFieldResource", dependent: :destroy

  accepts_nested_attributes_for :translations, allow_destroy: true

  def localized_options(locale = I18n.locale)
    # 1. Try to find translation for the specific locale
    trans = translations.detect { |t| t.locale.to_s == locale.to_s }
    # 2. Fallback to default locale if missing
    trans ||= translations.detect { |t| t.locale.to_s == I18n.default_locale.to_s }
    
    opts = trans&.options || []
    # 3. If options are empty but we have allowed_values in validations, use those as fallback
    if opts.blank? && validations["allowed_values"].present?
      opts = validations["allowed_values"].map { |v| { "value" => v, "label" => v.to_s.titleize } }
    end

    opts
  end

  # field_type controls input rendering and value validation:
  #   text (0), email (1), phone (2), number (3), textarea (4),
  #   select (5), multi_select (6), checkbox (7), file (8), date (9), url (10)
  enum :field_type, {
    text: 0, email: 1, phone: 2, number: 3, textarea: 4,
    select: 5, multi_select: 6, checkbox: 7, file: 8, date: 9, url: 10
  }, prefix: true

  # entity_type determines which model's data jsonb column stores the value:
  #   customer (0)     → Customer.data jsonb     e.g. customer.data["department"] = "sales"
  #   conversation (1) → Conversation.data jsonb e.g. conversation.data["priority_tier"] = "gold"
  #   contact_form (2) → Conversation.data jsonb (written on contact form submission)
  enum :entity_type, { customer: 0, conversation: 1, contact_form: 2 }, prefix: true

  # flags (FlagShihTzu bit fields):
  #   searchable — include this field's values in full-text search indexing
  #   filterable — show this field in filter/segment builder UI
  #   hidden     — defined for data storage but not rendered in standard UI
  #   readonly   — displayed but cannot be edited by agents via UI
  has_flags 1 => :searchable,
            2 => :filterable,
            3 => :hidden,
            4 => :is_readonly,
            column: "flags"

  validates :key, presence: true, uniqueness: { scope: :account_id, message: :taken_in_account },
                  format: { with: /\A[a-z0-9_]+\z/, message: :invalid_format }

  # validations jsonb structure:
  # {
  #   "min_length"     => 3,
  #   "max_length"     => 255,
  #   "min_value"      => 0,          (number fields)
  #   "max_value"      => 1_000_000,  (number fields)
  #   "pattern"        => "^[A-Z]",   (regex for text validation)
  #   "allowed_values" => ["a", "b"]  (whitelist — used as fallback for select fields)
  # }

  # configurations jsonb structure:
  # {
  #   "default_value" => "...",   (pre-filled value shown in forms/sidebars)
  #   "show_in_list"  => true,    (show as a column in customer/conversation list views)
  #   "width"         => "half"   (UI layout hint: "full" | "half")
  # }
end

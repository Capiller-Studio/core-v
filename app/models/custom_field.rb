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
  enum :entity_type, { customer: 0, conversation: 1 }, prefix: true

  #   searchable — include this field's values in full-text search indexing
  #   filterable — show this field in filter/segment builder UI
  #   hidden     — defined for data storage but not rendered in standard UI
  #   readonly   — displayed but cannot be edited by agents via UI
  has_flags 1 => :searchable,
            2 => :filterable,
            3 => :hidden,
            4 => :is_readonly,
            column: "flags"

  store_accessor :configurations, :default_value

  MAPPING_TARGETS = %w[
    customer.name
    customer.first_name
    customer.last_name
    customer.email
    conversation.title
    message.content
    conversation.priority
  ].freeze

  validates :mapped_to, inclusion: { in: MAPPING_TARGETS, allow_blank: true }
  validates :key, presence: true, uniqueness: { scope: :account_id, message: :taken_in_account },
                  format: { with: /\A[a-z0-9_]+\z/, message: :invalid_format }

  validate :validate_default_value

  before_validation :assign_entity_type_from_mapped_to

  private

  def validate_default_value
    return if default_value.blank?

    case field_type
    when "number"
      unless default_value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
        errors.add(:default_value, "must be a valid number")
      end
    when "email"
      unless default_value.to_s.match?(URI::MailTo::EMAIL_REGEXP)
        errors.add(:default_value, "must be a valid email format")
      end
    when "url"
      unless default_value.to_s.match?(/\Ahttps?:\/\//)
        errors.add(:default_value, "must be a valid URL")
      end
    end
  end

  private

  def assign_entity_type_from_mapped_to
    return if mapped_to.blank?

    if mapped_to.start_with?("customer.")
      self.entity_type = "customer"
    elsif mapped_to.start_with?("conversation.") || mapped_to.start_with?("message.")
      self.entity_type = "conversation"
    end
  end

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

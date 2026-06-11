class CreateCustomFields < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_fields, id: :uuid do |t|
      # key is the machine-readable identifier used as the JSON key when storing values
      # e.g. "department", "contract_value", "priority_level"
      # Must be unique per account — validated at model level
      t.string  :key,      null: false

      # field_type determines input rendering and value validation:
      #   text (0), email (1), phone (2), number (3), textarea (4),
      #   select (5), multi_select (6), checkbox (7), file (8), date (9), url (10)
      t.integer :field_type, null: false, default: 0

      # entity_type determines WHERE values are stored when this field is filled:
      #   customer (0)     → stored in Customer.data jsonb  e.g. { "department": "sales" }
      #   conversation (1) → stored in Conversation.data jsonb
      #   contact_form (2) → stored in Conversation.data jsonb on form submission
      # Future entity types can be added without schema changes
      t.integer :entity_type, null: false, default: 0

      t.integer :position  # Default global display order within this entity_type
      t.boolean :required, null: false, default: false
      t.boolean :system_provided, null: false, default: false

      t.integer :flags, null: false, default: 0
      # flags (FlagShihTzu bit fields):
      #   1 => :searchable   — include in full-text search
      #   2 => :filterable   — show in filter dropdowns
      #   3 => :hidden       — defined but hidden from UI (kept for data storage)
      #   4 => :readonly     — displayed but cannot be edited by agents

      # mapped_to determines if this field maps to a standard internal attribute:
      #   customer.email, customer.name, conversation.title, message.content
      t.string :mapped_to

      # validations jsonb — server-side and client-side validation rules:
      # {
      #   "min_length"     => 3,
      #   "max_length"     => 255,
      #   "min_value"      => 0,        (for number fields)
      #   "max_value"      => 1000000,  (for number fields)
      #   "pattern"        => "^[A-Z]", (regex pattern for text validation)
      #   "allowed_values" => ["a", "b"] (whitelist for select fields as fallback)
      # }
      t.jsonb :validations, null: false, default: {}

      # configurations jsonb — display and behavioural settings:
      # {
      #   "default_value"  => "...",  (pre-filled value)
      #   "show_in_list"   => true,   (show as a column in customer/conversation list views)
      #   "width"          => "half"  (UI layout hint: "full" | "half")
      # }
      t.jsonb :configurations, null: false, default: {}

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :key],         unique: true  # Keys must be unique per account
      t.index [:account_id, :entity_type]               # Fast filtering by entity type
      t.index [:account_id, :field_type]
      t.index [:account_id, :created_at]
      t.index [:account_id, :position]
    end
  end
end

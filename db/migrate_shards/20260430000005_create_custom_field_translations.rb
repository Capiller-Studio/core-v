class CreateCustomFieldTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_field_translations, id: :uuid do |t|
      t.string :locale, null: false

      t.string :label        # Displayed field label e.g. "Department" / "Abteilung"
      t.string :placeholder  # Input hint text e.g. "Select your department..."
      t.text   :description  # Help text shown below the field

      # options jsonb — used for select / multi_select field types:
      # Array of option objects where:
      #   - "value" is the locale-neutral machine key (always stored on submission)
      #   - "label" is the localized display string shown in the UI
      # Example:
      # [
      #   { "value": "billing",   "label": "Billing" },
      #   { "value": "technical", "label": "Technical Support" },
      #   { "value": "sales",     "label": "Sales" }
      # ]
      # When submitted, the "value" is written to the entity's data jsonb, not the label.
      # This ensures filtering/querying is always locale-neutral.
      t.jsonb :options, default: [], null: false

      t.references :custom_field, null: false, type: :uuid,
                   foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:custom_field_id, :locale], unique: true
    end
  end
end

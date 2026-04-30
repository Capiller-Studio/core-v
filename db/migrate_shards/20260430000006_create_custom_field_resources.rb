class CreateCustomFieldResources < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_field_resources, id: :uuid do |t|
      # Polymorphic resource: the entity this field is attached to.
      # Examples:
      #   resource_type: "Channel::ContactForm", resource_id: <form_uuid>
      #     → field appears in this specific contact form
      #   resource_type: "Account", resource_id: <account_uuid>  (future)
      #     → field appears in customer profile sidebar for this account
      t.string :resource_type, null: false
      t.uuid   :resource_id,   null: false

      # position overrides the CustomField's global default position for this specific resource
      t.integer :position

      # required_override: nil = use CustomField's default required value
      #                    true/false = override required setting for this resource only
      t.boolean :required_override

      # configurations jsonb — per-resource display overrides:
      # {
      #   "hidden"    => false,  (hide this field in this specific context)
      #   "read_only" => false,  (prevent editing in this specific context)
      #   "width"     => "full"  (UI layout override: "full" | "half")
      # }
      t.jsonb :configurations, null: false, default: {}

      t.references :custom_field, null: false, type: :uuid,
                   foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:resource_type, :resource_id]
      t.index [:custom_field_id, :resource_type, :resource_id], unique: true, name: "idx_custom_field_resources_unique"
    end
  end
end

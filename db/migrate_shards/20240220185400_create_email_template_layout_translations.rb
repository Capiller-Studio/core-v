class CreateEmailTemplateLayoutTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :email_template_layout_translations, id: :uuid do |t|
      # Published fields (read by mailers, written by publish action)
      t.text   :body
      t.jsonb  :design, default: {}
      t.text   :compiled_html

      # Draft fields (read/written by editor UI)
      t.text   :draft_body
      t.jsonb  :draft_design, default: {}

      t.string :locale, null: false

      t.references :email_template_layout, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:email_template_layout_id, :locale], unique: true, name: "idx_email_layout_translations_on_layout_id_and_locale"
    end
  end
end

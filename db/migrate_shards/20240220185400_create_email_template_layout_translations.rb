class CreateEmailTemplateLayoutTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :email_template_layout_translations, id: :uuid do |t|
      t.text   :body
      t.string :locale, null: false

      t.references :email_template_layout, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:email_template_layout_id, :locale], unique: true, name: "idx_email_layout_translations_on_layout_id_and_locale"
    end
  end
end

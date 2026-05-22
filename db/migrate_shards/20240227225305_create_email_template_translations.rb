class CreateEmailTemplateTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :email_template_translations do |t|
      # Published fields (read by mailers, written by publish action)
      t.string  :subject
      t.text    :body
      t.jsonb   :design, default: {}
      t.text    :compiled_html

      # Draft fields (read/written by editor UI)
      t.string  :draft_subject
      t.text    :draft_body
      t.jsonb   :draft_design, default: {}

      t.string  :locale, null: false

      t.references :email_template, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:subject, :locale]
      t.index [:email_template_id, :locale], unique: true
    end
  end
end

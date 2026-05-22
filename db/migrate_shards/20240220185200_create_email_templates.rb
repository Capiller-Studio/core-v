class CreateEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :email_templates, id: :uuid do |t|
      t.string  :name
      t.integer :status, default: 0, null: false

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :email_template_layout, null: true, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
    end
  end
end

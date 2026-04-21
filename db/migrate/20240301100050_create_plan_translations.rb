class CreatePlanTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :plan_translations, id: :uuid do |t|
      t.string :locale, null: false
      t.string :display_name, null: false
      t.text   :description

      t.references :plan, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:plan_id, :locale], unique: true
    end
  end
end

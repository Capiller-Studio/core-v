class CreateCsatSurveyResponses < ActiveRecord::Migration[7.1]
  def change
    create_table :csat_survey_responses, id: :uuid do |t|
      t.integer    :rating, null: true
      t.text       :content
      t.integer    :status, null: false, default: 0 # 0=pending, 1=submitted

      t.references :account,      null: false, foreign_key: false, type: :uuid, index: true
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :customer,     null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :message,      null: true,  foreign_key: { on_delete: :nullify }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :rating]
    end
  end
end

class CreateCsatSurveys < ActiveRecord::Migration[7.1]
  def change
    create_table :csat_surveys, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: false, index: true
      t.references :email_template, type: :uuid, null: true, foreign_key: { to_table: :email_templates, on_delete: :nullify }, index: true
      t.string :name, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    create_table :csat_survey_translations do |t|
      t.references :csat_survey, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :locale, null: false, index: true
      
      t.string :prompt
      t.string :portal_title
      t.text :portal_subtitle
      t.string :portal_feedback_label

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :csat_survey_translations, [:csat_survey_id, :locale], unique: true, name: 'index_csat_translations_on_survey_and_locale'

    # Add csat_survey_id to inboxes
    add_reference :inboxes, :csat_survey, type: :uuid, null: true, foreign_key: { to_table: :csat_surveys, on_delete: :nullify }, index: true
    
    # Add csat_survey_id to csat_survey_responses so the portal knows which copy to render
    add_reference :csat_survey_responses, :csat_survey, type: :uuid, null: true, foreign_key: { to_table: :csat_surveys, on_delete: :nullify }, index: true
  end
end

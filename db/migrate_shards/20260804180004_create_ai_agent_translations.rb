class CreateAiAgentTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_agent_translations, id: :uuid do |t|
      t.references :agent, type: :uuid, null: false, foreign_key: { to_table: :ai_agents, on_delete: :cascade }, index: false
      t.string :locale,           null: false

      # Translatable customer-facing fields
      t.string :greeting_message                # First message shown to customer
      t.string :handoff_message                 # Message when escalating to human
      t.string :fallback_message                # When no article matches

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
      
      t.index [:agent_id, :locale], unique: true
    end
  end
end

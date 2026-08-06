class CreateAiAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_agents, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: false, index: true
      t.references :portal,  type: :uuid, null: true,  foreign_key: { to_table: :help_center_portals, on_delete: :nullify }

      # Core Config
      t.string  :name,             null: false, default: "AI Assistant"
      t.integer :status,           null: false, default: 0  # enum: active, inactive
      t.integer :agent_type,       null: false, default: 0  # enum: help_center_bot, custom

      # Behavior & Training
      t.text    :system_prompt
      t.integer :tone,             null: false, default: 0  # enum: professional, friendly, neutral, concise
      t.string  :language,         null: false, default: "en"

      # Guardrails
      t.integer :max_exchanges,         null: false, default: 5
      t.float   :confidence_threshold,  null: false, default: 0.7

      # Metrics (denormalized for dashboard speed)
      t.integer :total_conversations,   null: false, default: 0
      t.integer :total_resolutions,     null: false, default: 0
      t.integer :total_handoffs,        null: false, default: 0

      t.jsonb   :configurations,        null: false, default: {}
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
      
      t.index [:account_id, :status]
    end

    add_reference :inboxes, :ai_agent, type: :uuid, null: true, foreign_key: { to_table: :ai_agents, on_delete: :nullify }
  end
end

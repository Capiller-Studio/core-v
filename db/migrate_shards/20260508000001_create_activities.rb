# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities, id: :uuid do |t|
      # Core Associations
      t.references :account, type: :uuid, null: false, index: true, foreign_key: false
      
      # Polymorphic Trackable (The object being changed)
      t.references :trackable, polymorphic: true, type: :uuid, null: false, index: true
      
      # Polymorphic Actor (The User, Customer, or System)
      t.references :actor, polymorphic: true, type: :uuid, null: true, index: true
      
      # Event Details
      t.string :event_key, null: false, index: true # e.g., "article.translation_updated"
      
      # Data Payload
      t.jsonb :object_snapshot, null: false, default: {} # Full state after event
      t.jsonb :object_changes,  null: false, default: {} # Attribute diff for "Undo"
      t.jsonb :event_data,      null: false, default: {} # Interpolation values for i18n
      
      # Request Context (Auditing)
      t.jsonb :metadata,        null: false, default: {} # IP, User Agent, Request ID
      
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    # Composite indexes for common lookups
    add_index :activities, [:trackable_type, :trackable_id, :created_at], name: "index_activities_on_trackable_and_created_at"
    add_index :activities, [:account_id, :created_at], name: "index_activities_on_account_id_and_created_at"

    # GIN indexes for instantaneous JSONB payload search and key filtering
    add_index :activities, :object_changes, using: :gin, name: "index_activities_on_object_changes_gin"
    add_index :activities, :object_snapshot, using: :gin, name: "index_activities_on_object_snapshot_gin"
  end
end

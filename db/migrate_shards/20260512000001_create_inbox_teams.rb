# frozen_string_literal: true

class CreateInboxTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_teams, id: :uuid do |t|
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :team,  null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:inbox_id, :team_id], unique: true
    end
  end
end

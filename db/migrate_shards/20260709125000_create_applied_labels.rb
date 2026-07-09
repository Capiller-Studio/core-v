class CreateAppliedLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :applied_labels, id: :uuid do |t|
      t.references :label, null: false, foreign_key: false, type: :uuid
      t.references :labelable, polymorphic: true, null: false, type: :uuid
      t.references :account, null: false, foreign_key: false, type: :uuid

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:labelable_id, :labelable_type, :label_id], unique: true, name: "index_applied_labels_uniqueness"
    end
  end
end

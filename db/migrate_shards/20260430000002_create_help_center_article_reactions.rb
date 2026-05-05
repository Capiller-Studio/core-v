class CreateHelpCenterArticleReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :help_center_article_reactions, id: :uuid do |t|
      # reaction_type: happy (0) 😃, neutral (1) 😐, sad (2) 😔
      # Used to gauge article quality and identify content needing improvement
      t.integer :reaction_type, null: false

      t.string  :ip_address  # Used to prevent duplicate reactions per visitor
      t.string  :session_id  # Browser session fingerprint as secondary dedup guard

      t.references :article, null: false, type: :uuid,
                   foreign_key: { to_table: :help_center_articles, on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      # One reaction per article per IP address
      t.index [:article_id, :ip_address], unique: true
      t.index :reaction_type
    end
  end
end

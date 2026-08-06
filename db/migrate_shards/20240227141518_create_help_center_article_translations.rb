class CreateHelpCenterArticleTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_article_translations do |t|
      t.string  :title
      t.text    :meta_title
      t.text    :content
      t.text    :meta_description
      t.string  :meta_keywords, array: true, default: [], null: false
      t.string  :locale, null: false

      # Draft fields for editor UI
      t.string  :draft_title
      t.text    :draft_content

      # slug is locale-specific for proper multi-language SEO URLs
      # e.g. /en/guides/setup-whatsapp vs /es/guias/configurar-whatsapp
      # Stores only the slug segment — locale prefix is handled by the router
      t.string  :slug

      # Pre-computed plain-text excerpt for search result previews (stripped of HTML/Markdown)
      t.text    :search_excerpt

      # AI Training fields
      t.jsonb   :content_embedding
      t.boolean :ai_training_synced, default: false, null: false

      t.references :article, null: false, type: :uuid, foreign_key: { to_table: :help_center_articles, on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :locale
      t.index [:title, :locale]
      t.index [:article_id, :locale], unique: true
      t.index [:article_id, :slug]    # For slug-based lookups within an article's translations
      t.index :ai_training_synced
    end
  end
end

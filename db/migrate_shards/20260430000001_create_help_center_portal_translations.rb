class CreateHelpCenterPortalTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :help_center_portal_translations, id: :uuid do |t|
      t.string :locale, null: false

      # Hero section text
      t.string :hero_title       # e.g. "How can we help?"
      t.string :hero_subtitle    # e.g. "Search our knowledge base or browse categories below"
      t.string :search_placeholder # e.g. "Search documentation, guides, and APIs..."

      # Navigation / branding text
      t.string :header_tagline   # Optional short tagline next to the logo

      # Footer
      t.string :footer_text      # e.g. "© 2025 Acme Corp. All rights reserved."

      # Contact page
      t.string :contact_page_title    # e.g. "Submit a Request"
      t.string :contact_page_subtitle # e.g. "Fill in the form below and we'll get back to you."

      t.references :portal, null: false, type: :uuid,
                   foreign_key: { to_table: :help_center_portals, on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:portal_id, :locale], unique: true
    end
  end
end

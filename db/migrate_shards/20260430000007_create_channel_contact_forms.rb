class CreateChannelContactForms < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_contact_forms, id: :uuid do |t|
      t.string  :name                  # Internal name e.g. "Website Support Form"
      t.string  :submit_redirect_url   # Custom redirect URL after form submission
      t.string  :secret, null: false   # Unique embed key for JS snippet (like Channel::WebWidget)
      t.integer :status, null: false, default: 0
      t.integer :flags,  null: false, default: 0
      # flags (FlagShihTzu bit fields):
      #   1 => :require_login          — require customer login before submitting
      #   2 => :allow_attachments      — allow file uploads in the form
      #   3 => :send_confirmation_email — send auto-reply email to submitter
      #   4 => :spam_protection_enabled — enable reCAPTCHA/Turnstile

      # configurations jsonb — form behaviour settings:
      # {
      #   "notification_emails"      => ["team@..."],   (additional emails notified on submission)
      #   "success_message_i18n_key" => "contact_form.success" (i18n key for success message)
      # }
      t.jsonb :configurations, null: false, default: {}
      
      t.jsonb :ui_configurations, null: false, default: {}

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.references :outbound_channel, polymorphic: true, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :created_at]
      t.index :secret, unique: true  # Used to identify the form in embed snippets and API calls
    end

    create_table :channel_contact_form_translations, id: :uuid do |t|
      t.references :contact_form, type: :uuid, null: false, foreign_key: { to_table: :channel_contact_forms, on_delete: :cascade }, index: { name: 'index_ccft_on_contact_form_id' }
      t.string :locale, null: false
      t.string :title
      t.string :subtitle
      t.string :success_message
      t.string :submit_button_text
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:contact_form_id, :locale], unique: true, name: 'index_ccft_on_contact_form_id_and_locale'
    end

    add_reference :channel_web_widgets, :pre_chat_form, type: :uuid, index: true, foreign_key: { to_table: :channel_contact_forms, on_delete: :nullify }
    add_reference :help_center_portals, :contact_form_channel, type: :uuid, index: true, foreign_key: { to_table: :channel_contact_forms, on_delete: :nullify }
  end
end

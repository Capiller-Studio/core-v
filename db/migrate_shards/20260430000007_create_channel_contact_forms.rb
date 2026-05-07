class CreateChannelContactForms < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_contact_forms, id: :uuid do |t|
      t.string  :name                  # Internal name e.g. "Website Support Form"
      t.string  :secret, null: false   # Unique embed key for JS snippet (like Channel::WebWidget)
      t.integer :status, null: false, default: 0
      t.integer :flags,  null: false, default: 0
      # flags (FlagShihTzu bit fields):
      #   1 => :require_login          — require customer login before submitting
      #   2 => :allow_attachments      — allow file uploads in the form
      #   3 => :send_confirmation_email — send auto-reply email to submitter

      # configurations jsonb — form behaviour settings:
      # {
      #   "submit_redirect_url"      => "https://...",  (redirect after successful submission)
      #   "notification_emails"      => ["team@..."],   (additional emails notified on submission)
      #   "success_message_i18n_key" => "contact_form.success" (i18n key for success message)
      # }
      t.jsonb :configurations, null: false, default: {}

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      # portal_id is optional — a contact form can exist independently (embeddable on own website)
      # and be linked to a portal when the portal's contact page feature is enabled
      t.references :portal, foreign_key: false, type: :uuid, index: true
      t.references :outbound_channel, polymorphic: true, type: :uuid, index: true, foreign_key: { on_delete: :nullify }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :created_at]
      t.index :secret, unique: true  # Used to identify the form in embed snippets and API calls
    end
  end
end

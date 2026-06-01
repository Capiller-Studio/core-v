# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_contact_forms
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  flags          :integer          default(0), not null
#  name           :string
#  secret         :string           not null
#  status         :integer          default("active"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  portal_id      :uuid
#
# Indexes
#
#  index_channel_contact_forms_on_account_id             (account_id)
#  index_channel_contact_forms_on_account_id_and_status  (account_id,status)
#  index_channel_contact_forms_on_portal_id              (portal_id)
#  index_channel_contact_forms_on_secret                 (secret) UNIQUE
#
module Channel
  class ContactForm < ShardRecord
    include Routable
    include FlagShihTzu

    belongs_to :account
    # portal is optional — a contact form can be used standalone (embedded on own website)
    # or linked to a Help Center portal for the /contact page feature
    belongs_to :portal, class_name: "HelpCenter::Portal", optional: true
    belongs_to :outbound_channel, polymorphic: true, optional: true

    # Gets its own Inbox via the standard channel polymorphic pattern.
    # Conversations from form submissions land in this Inbox with source: :help_center
    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    # Custom fields attached to this form via CustomFieldResource (polymorphic)
    has_many :custom_field_resources, as: :resource, class_name: "CustomFieldResource", dependent: :destroy
    has_many :custom_fields, through: :custom_field_resources

    enum :status, { active: 0, inactive: 1 }

    # flags (FlagShihTzu bit fields):
    #   require_login          — customer must be logged in to submit the form
    #   allow_attachments      — allow file uploads (subject to account storage limits)
    #   send_confirmation_email — auto-send a receipt email to the submitter
    has_flags 1 => :require_login,
              2 => :allow_attachments,
              3 => :send_confirmation_email,
              column: "flags"

    before_validation :ensure_secret, on: :create

    validates :secret, presence: true, uniqueness: true

    # configurations jsonb structure:
    # {
    #   "submit_redirect_url"      => "https://...",         (redirect URL after successful submission)
    #   "notification_emails"      => ["team@example.com"],  (additional email addresses notified on submission)
    #   "success_message_i18n_key" => "contact_form.success" (i18n key for the thank-you message shown after submit)
    # }

    def hmac_token
      secret
    end

    private

    def ensure_secret
      self.secret ||= SecureRandom.hex(24)
    end
  end
end

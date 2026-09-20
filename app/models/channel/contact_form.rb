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
    include Channelable
    include Routable
    include FlagShihTzu
    include Translateable
    include Trackable

    TRANSLATABLE_FIELDS = %i[title subtitle success_message submit_button_text].freeze

    translates(*TRANSLATABLE_FIELDS)

    belongs_to :account

    def supported_formatting
      [:bold, :italic, :strikethrough, :code, :ul, :ol, :link, :image, :file]
    end

    has_many :portals, class_name: "HelpCenter::Portal", foreign_key: :contact_form_channel_id, dependent: :nullify
    belongs_to :outbound_channel, polymorphic: true, optional: true

    # Gets its own Inbox via the standard channel polymorphic pattern.
    # Conversations from form submissions land in this Inbox with source: :help_center
    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    def inbox
      primary_inbox || inboxes.first
    end

    # Custom fields attached to this form via CustomFieldResource (polymorphic)
    has_many :custom_field_resources, as: :resource, class_name: "CustomFieldResource", dependent: :destroy
    has_many :custom_fields, -> { order('custom_field_resources.position ASC') }, through: :custom_field_resources

    enum :status, { active: 0, inactive: 1 }

    store_accessor :ui_configurations, :theme_color, :position, :custom_css

    def display_title(locale = I18n.locale)
      title.presence || I18n.t("contact_form.default_title", default: "Send us a message")
    end

    def display_subtitle(locale = I18n.locale)
      subtitle.presence || configurations["welcome_message"].presence || I18n.t("contact_form.default_subtitle", default: "Fill out the form below and we'll get back to you.")
    end

    def display_submit_button_text(locale = I18n.locale)
      submit_button_text.presence || I18n.t("contact_form.send_message", default: "Send Message")
    end

    # flags (FlagShihTzu bit fields):
    #   require_login          — customer must be logged in to submit the form
    #   allow_attachments      — allow file uploads (subject to account storage limits)
    #   send_confirmation_email — auto-send a receipt email to the submitter
    has_flags 1 => :require_login,
              2 => :allow_attachments,
              3 => :send_confirmation_email,
              4 => :spam_protection_enabled,
              column: "flags"

    before_validation :ensure_secret, on: :create

    validates :secret, presence: true, uniqueness: true
    validates :submit_redirect_url, length: { maximum: 255 }, allow_blank: true
    validates :outbound_channel_type, inclusion: { in: ['Channel::Email'] }, allow_blank: true
    
    validate :validate_submit_redirect_url
    validate :validate_outbound_channel_ownership

    # configurations jsonb structure:
    # {
    #   "success_message_i18n_key" => "contact_form.success" (i18n key for the thank-you message shown after submit)
    # }

    def hmac_token
      secret
    end

    private

    def ensure_secret
      self.secret ||= SecureRandom.hex(24)
    end

    def validate_outbound_channel_ownership
      return if outbound_channel.blank?
      
      unless outbound_channel.account_id == account_id
        errors.add(:outbound_channel, "must belong to your account")
      end
    end

    def validate_submit_redirect_url
      return if submit_redirect_url.blank?

      uri = URI.parse(submit_redirect_url.to_s.strip)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:submit_redirect_url, "must be a valid HTTP or HTTPS URL")
        return
      end

      forbidden_hosts = ['localhost', '127.0.0.1', '0.0.0.0', '::1']
      if forbidden_hosts.include?(uri.host) || uri.host.to_s.end_with?('.local')
        errors.add(:submit_redirect_url, "cannot be a local or internal address")
        return
      end

      require 'ipaddr'
      begin
        ip = IPAddr.new(uri.host)
        if ip.private? || ip.loopback? || ip.link_local?
          errors.add(:submit_redirect_url, "cannot be a private IP address")
        end
      rescue IPAddr::InvalidAddressError
        # Valid domain name, not an IP
      end
    rescue URI::InvalidURIError
      errors.add(:submit_redirect_url, "is not a valid URL format")
    end
  end
end

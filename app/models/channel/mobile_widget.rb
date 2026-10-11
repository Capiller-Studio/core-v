# frozen_string_literal: true

module Channel
  class MobileWidget < ShardRecord
    include Channelable
    include Routable
    include FlagShihTzu
    include Translateable
    include Trackable

    TRANSLATABLE_FIELDS = %i[header_title welcome_title welcome_tagline reply_time_text pre_chat_title pre_chat_subtitle].freeze
    IDENTIFIER_PREFIX = "dbk_app_"

    belongs_to :account
    belongs_to :portal, class_name: "HelpCenter::Portal", optional: true
    belongs_to :pre_chat_form, class_name: "Channel::ContactForm", optional: true
    belongs_to :fallback_channel, polymorphic: true, optional: true

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"
    accepts_nested_attributes_for :primary_inbox, update_only: true

    has_many :customer_devices, through: :inboxes

    has_one_attached :logo
    validates :logo, content_type: ["image/png", "image/jpeg", "image/svg+xml", "image/webp"],
                     size: { less_than: 2.megabytes },
                     if: -> { logo.attached? }

    encrypts :secret, deterministic: true
    encrypts :apns_key
    encrypts :fcm_service_account

    translates(*TRANSLATABLE_FIELDS)

    has_flags 1 => :anonymous_allowed,
              2 => :secure_identity_enforced,
              3 => :help_center_enabled,
              4 => :pre_chat_form_enabled,
              5 => :push_enabled,
              6 => :custom_branding,
              7 => :attachments_enabled,
              column: "flags"

    enum :status, { active: 0, suspended: 1 }
    enum :apns_environment, { sandbox: 0, production: 1 }, prefix: :apns

    store_accessor :ui_configurations, :theme_color, :header_title_color
    store_accessor :configurations, :max_attachment_mb, :push_preview_mode

    before_validation :ensure_identifier_and_secret, on: :create
    before_validation :extract_fcm_project_id, if: :fcm_service_account_changed?

    validates :name, presence: true
    validates :identifier, presence: true, uniqueness: true
    validates :secret, presence: true
    validates :apns_key_id, length: { is: 10 }, allow_blank: true
    validates :apns_team_id, length: { is: 10 }, allow_blank: true
    validate :validate_fallback_channel_ownership, if: -> { fallback_channel_id.present? }

    alias_attribute :apns_bundle_id, :ios_bundle_id

    def routing_identifier
      identifier
    end

    def routing_type
      "mobile_widget"
    end

    def hmac_token
      secret
    end

    def fallback_locale
      default_locale.presence || super
    end

    def locales
      if portal.present? && portal.locales.present?
        portal.locales
      else
        ([default_locale.presence || "en"] + translations.pluck(:locale)).compact_blank.uniq
      end
    end

    def supported_formatting
      [:bold, :italic, :strikethrough, :code, :ul, :ol, :link, :image, :file]
    end

    def apns_configured?
      [apns_key, apns_key_id, apns_team_id, ios_bundle_id].all?(&:present?)
    end

    def fcm_configured?
      fcm_service_account.present? && fcm_project_id.present?
    end

    def regenerate_secret!
      update!(
        data: data.merge("secret_rotated_at" => Time.current.iso8601),
        secret: SecureRandom.hex(32)
      )
    end

    private

    def ensure_identifier_and_secret
      self.identifier ||= "#{IDENTIFIER_PREFIX}#{SecureRandom.hex(12)}"
      self.secret     ||= SecureRandom.hex(32)
    end

    def extract_fcm_project_id
      return if fcm_service_account.blank?

      parsed = JSON.parse(fcm_service_account.to_s) rescue nil
      self.fcm_project_id = parsed["project_id"] if parsed.is_a?(Hash)
    end

    def validate_fallback_channel_ownership
      if fallback_channel.blank?
        errors.add(:fallback_channel, "must belong to your account") if fallback_channel_id.present?
        return
      end

      errors.add(:fallback_channel, "must belong to your account") unless fallback_channel.account_id == account_id
    end
  end
end

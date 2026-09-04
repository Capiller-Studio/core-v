# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_whatsapps
#
#  id                  :uuid             not null, primary key
#  api_key             :string
#  configurations      :jsonb            not null
#  data                :jsonb            not null
#  full_phone_number   :string           not null
#  name                :string
#  phone_code          :string
#  phone_number        :string
#  service             :integer          default("cloud_api"), not null
#  status              :integer          default("active"), not null
#  webhook_secret      :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             not null
#  business_account_id :string
#  phone_number_id     :string
#
# Indexes
#
#  index_channel_whatsapps_on_account_id                 (account_id)
#  index_channel_whatsapps_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_whatsapps_on_account_id_and_name        (account_id,name)
#  index_channel_whatsapps_on_full_phone_number          (full_phone_number) UNIQUE
#  index_channel_whatsapps_on_service                    (service)
#  index_channel_whatsapps_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class Whatsapp < ShardRecord
    include Channelable
    include Routable
    include Reauthorizable
    include FlagShihTzu
    include Trackable

    # Graph API version — single source of truth for all WhatsApp Cloud API calls.
    GRAPH_API_VERSION = "v26.0"
    GRAPH_API_BASE = "https://graph.facebook.com"

    belongs_to :account

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    accepts_nested_attributes_for :primary_inbox, update_only: true

    encrypts :api_key

    enum :status, { active: 0, disconnected: 1 }
    enum :service, { cloud_api: 0 }

    def supported_formatting
      [:bold, :italic, :strikethrough, :code, :image, :file]
    end

    has_flags 1 => :provider_embedded_signup, column: "flags"

    store_accessor :configurations, :template_name, :template_language

    validates :phone_number_id, presence: true, uniqueness: { message: "is already connected" }
    validates :full_phone_number, uniqueness: { message: "is already connected" }, allow_nil: true
    validates :business_account_id, presence: true
    validates :api_key, presence: true
    before_validation :generate_webhook_secret, on: :create
    before_validation :calculate_full_phone_number
    before_destroy :unsubscribe_from_webhooks

    # --- Routable overrides ---
    # WhatsApp Cloud API routes all webhook events globally via phone_number_id

    def routing_identifier
      phone_number_id
    end

    def routing_type
      "whatsapp"
    end

    # --- API helpers (shared by MessageSender, MessageCreator, etc.) ---

    def api_headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{api_key}"
      }
    end

    def graph_api_url(path)
      "#{GRAPH_API_BASE}/#{GRAPH_API_VERSION}/#{path}"
    end

    def phone_number_endpoint
      graph_api_url(phone_number_id)
    end

    def business_account_endpoint
      graph_api_url(business_account_id)
    end

    # Full public webhook URL for display in the edit page.
    # Users paste this into Meta's webhook configuration.
    def webhook_url
      host = ENV.fetch("FRONTEND_URL", "https://deskbolic.app")
      "#{host}/webhooks/whatsapp/#{account_id}/#{id}"
    end

    def template_language
      super.presence || "en_US"
    end

    def sync_templates
      Channels::Whatsapp::CloudApi::TemplateFetcher.call(whatsapp_channel: self)
    end

    def approved_templates
      message_templates || []
    end

    private

    def calculate_full_phone_number
      if phone_code.present? && phone_number.present?
        sanitized_code = phone_code.to_s.delete('+').gsub(/\D/, '')
        sanitized_number = phone_number.to_s.gsub(/\D/, '')
        self.full_phone_number = "+#{sanitized_code}#{sanitized_number}"
      elsif full_phone_number.present?
        digits = full_phone_number.to_s.gsub(/\D/, '')
        self.full_phone_number = "+#{digits}" if digits.present?
      end
    end

    def generate_webhook_secret
      self.webhook_secret ||= SecureRandom.hex(24)
    end

    def unsubscribe_from_webhooks
      return if business_account_id.blank?

      # 1. Try with channel access token
      response = begin
        HTTParty.delete(
          "#{GRAPH_API_BASE}/#{GRAPH_API_VERSION}/#{business_account_id}/subscribed_apps",
          headers: api_headers
        )
      rescue StandardError => e
        Rails.logger.warn("WhatsApp unsubscribe_from_webhooks warning for WABA #{business_account_id}: #{e.message}")
        nil
      end

      # 2. Fallback to App Access Token if channel token is invalid/expired
      if !response || !response.success?
        app_id = (Rails.application.credentials.dig(:channels, :whatsapp, :app_id).presence ||
                  Rails.application.credentials.dig(:channels, :facebook, :app_id))&.to_s&.strip
        app_secret = (Rails.application.credentials.dig(:channels, :whatsapp, :app_secret).presence ||
                      Rails.application.credentials.dig(:channels, :facebook, :app_secret))&.to_s&.strip
        if app_id.present? && app_secret.present?
          begin
            HTTParty.delete(
              "#{GRAPH_API_BASE}/#{GRAPH_API_VERSION}/#{business_account_id}/subscribed_apps",
              headers: {
                "Authorization" => "Bearer #{app_id}|#{app_secret}",
                "Content-Type" => "application/json"
              }
            )
          rescue StandardError => e
            Rails.logger.warn("WhatsApp unsubscribe app token warning for WABA #{business_account_id}: #{e.message}")
          end
        end
      end
    end
  end
end

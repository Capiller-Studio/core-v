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

    # Graph API version — single source of truth for all WhatsApp Cloud API calls.
    GRAPH_API_VERSION = "v25.0"
    GRAPH_API_BASE = "https://graph.facebook.com"

    belongs_to :account

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    accepts_nested_attributes_for :primary_inbox, update_only: true

    encrypts :api_key

    enum :status, { active: 0, disconnected: 1 }
    enum :service, { cloud_api: 0 }

    has_flags 1 => :provider_embedded_signup, column: "flags"

    validates :full_phone_number, presence: true, uniqueness: { message: "is already connected" }
    validates :phone_number_id, presence: true
    validates :business_account_id, presence: true
    validates :api_key, presence: true

    before_validation :generate_webhook_secret, on: :create
    before_validation :calculate_full_phone_number

    # --- Routable overrides ---

    def routing_identifier
      full_phone_number
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
      host = Rails.application.credentials.dig(Rails.env.to_sym, :host) || Rails.application.credentials.dig(:host)
      "#{host}/webhooks/whatsapp/#{account_id}/#{id}"
    end

    private

    def calculate_full_phone_number
      if phone_code.present? && phone_number.present?
        self.full_phone_number = "+#{phone_code.to_s.delete('+').strip}#{phone_number.to_s.strip}"
      end
    end

    def generate_webhook_secret
      self.webhook_secret ||= SecureRandom.hex(24)
    end
  end
end

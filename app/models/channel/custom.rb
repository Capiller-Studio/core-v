# frozen_string_literal: true

require 'resolv'
require 'ipaddr'

module Channel
  class Custom < ShardRecord
    include Channelable
    include Routable
    include Trackable
    
    belongs_to :account

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"
    accepts_nested_attributes_for :primary_inbox, update_only: true

    has_many :webhook_deliveries, class_name: "Webhook::Delivery", as: :resource, dependent: :destroy

    encrypts :webhook_secret
    encrypts :hmac_token

    validates :identifier, presence: true, uniqueness: { scope: :account_id, message: "is already in use" }
    validate :validate_webhook_url_security, if: -> { webhook_url.present? }

    enum :status, { active: 0, disconnected: 1 }

    before_validation :generate_identifier, on: :create
    before_validation :generate_webhook_secret, on: :create
    before_validation :generate_hmac_token, on: :create

    # --- Routable overrides ---

    def routing_identifier
      identifier
    end

    def routing_type
      "custom"
    end

    # --- Webhooks ---

    # Public endpoint where the customer sends their payloads to us.
    def webhook_endpoint
      host = ENV.fetch("FRONTEND_URL", "https://rely.capiller.com")
      "#{host}/webhooks/custom/#{account_id}/#{id}"
    end

    private

    def generate_identifier
      self.identifier = name.parameterize if identifier.blank? && name.present?
      
      # Ensure uniqueness by appending a random hex if conflict exists
      if identifier.present?
        while Channel::Custom.exists?(account_id: account_id, identifier: identifier)
          self.identifier = "#{name.parameterize}-#{SecureRandom.hex(4)}"
        end
      end
    end

    def generate_webhook_secret
      self.webhook_secret ||= SecureRandom.hex(24)
    end

    def generate_hmac_token
      self.hmac_token ||= SecureRandom.hex(32)
    end

    def validate_webhook_url_security
      return if webhook_url.blank?

      result = Security::UrlValidator.validate(webhook_url)
      errors.add(:webhook_url, result[:error]) unless result[:valid]
    end
  end
end

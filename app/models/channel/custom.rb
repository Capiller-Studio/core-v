# frozen_string_literal: true

require 'resolv'
require 'ipaddr'

module Channel
  class Custom < ShardRecord
    include Channelable
    include Routable
    
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
      host = ENV.fetch("FRONTEND_URL", "https://deskbolic.app")
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
      # 1. Basic format validation
      unless webhook_url.to_s.match?(/\Ahttps?:\/\/[^\s\/$.?#].[^\s]*\z/i)
        errors.add(:webhook_url, "must be a valid URL format")
        return
      end

      uri = URI.parse(webhook_url)
      
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:webhook_url, "must be an HTTP or HTTPS URL")
        return
      end

      # Skip internal IP checks in test and development environments to allow local testing
      return if Rails.env.development? || Rails.env.test?

      # 2. Prevent explicit localhost/internal hostnames
      if %w[localhost 127.0.0.1 0.0.0.0].include?(uri.host) || uri.host.to_s.end_with?('.local')
        errors.add(:webhook_url, "cannot point to localhost or internal network spaces")
        return
      end

      # 3. DNS resolution and IP checks

      begin
        ip_addresses = Resolv.getaddresses(uri.host)
        
        # Block if no IPs resolve
        if ip_addresses.empty?
          errors.add(:webhook_url, "could not be resolved")
          return
        end

        ip_addresses.each do |ip|
          if internal_ip?(ip)
            errors.add(:webhook_url, "cannot point to internal or private IP addresses")
            break
          end
        end
      rescue Resolv::ResolvError
        errors.add(:webhook_url, "domain could not be resolved")
      rescue StandardError => e
        errors.add(:webhook_url, "is invalid")
      end
    end

    def internal_ip?(ip_string)
      ip = IPAddr.new(ip_string)
      
      # Covers 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, etc.
      ip.loopback? || ip.private? || ip.link_local?
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end

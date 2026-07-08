# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_emails
#
#  id                  :uuid             not null, primary key
#  configurations      :jsonb            not null
#  email               :string
#  forward_email       :string
#  imap_configurations :jsonb            not null
#  name                :string
#  service             :integer
#  smtp_configurations :jsonb            not null
#  status              :integer          default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             not null
#
# Indexes
#
#  index_channel_emails_on_account_id                 (account_id)
#  index_channel_emails_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_emails_on_account_id_and_name        (account_id,name)
#  index_channel_emails_on_email                      (email) UNIQUE
#  index_channel_emails_on_forward_email              (forward_email) UNIQUE
#  index_channel_emails_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class Email < ShardRecord
    include Channelable
    include Routable
    include FlagShihTzu

    belongs_to :account

    enum :status, { active: 0 }

    has_flags 1 => :imap_enabled, 2 => :smtp_enabled, column: 'flags'

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"
    accepts_nested_attributes_for :primary_inbox, update_only: true

    has_secure_token :forward_email_token

    # Encrypt credentials in the database (requires active_record_encryption keys in credentials)
    encrypts :smtp_configurations
    encrypts :imap_configurations

    validates :email, uniqueness: { scope: :account_id }, allow_nil: true
    validates :forward_email, uniqueness: true, allow_blank: true

    validate :validate_imap_configurations, if: :imap_enabled?
    validate :validate_smtp_configurations, if: :smtp_enabled?

    def supported_formatting
      [:bold, :italic, :strikethrough, :code, :ul, :ol, :link, :image, :file]
    end

    before_create :generate_forward_email
    after_save :register_forward_email_routing
    after_destroy :remove_forward_email_routing

    # IMAP config: { address:, port:, username:, password:, enable_ssl: }
    def imap_config
      @imap_config ||= imap_configurations.symbolize_keys
    end

    # SMTP config: { address:, port:, username:, password:, domain:, authentication:, enable_starttls: }
    def smtp_config
      @smtp_config ||= smtp_configurations.symbolize_keys
    end

    # Build ActionMailer delivery options from smtp_configurations
    def smtp_delivery_options
      return {} unless smtp_enabled?

      {
        address: smtp_config[:address],
        port: smtp_config[:port] || 587,
        user_name: smtp_config[:username],
        password: smtp_config[:password],
        domain: smtp_config[:domain],
        authentication: (smtp_config[:authentication] || "plain").to_sym,
        enable_starttls_auto: smtp_config[:enable_starttls] != false
      }.compact
    end

    # Forward email domain extracted for reply-to construction
    def forward_email_domain
      return nil if forward_email.blank?

      forward_email.split("@").last
    end

    def forwarding_verified?
      forwarding_verified_at.present?
    end

    private

    def validate_imap_configurations
      if imap_configurations.blank? || imap_configurations["address"].blank?
        errors.add(:base, "IMAP Address is required when IMAP is enabled")
      elsif imap_configurations["address"].match?(/\s/)
        errors.add(:base, "IMAP Address cannot contain spaces")
      end

      errors.add(:base, "IMAP Username is required when IMAP is enabled") if imap_configurations.blank? || imap_configurations["username"].blank?
      errors.add(:base, "IMAP Password is required when IMAP is enabled") if imap_configurations.blank? || imap_configurations["password"].blank?

      if imap_configurations.present? && imap_configurations["port"].present?
        port = imap_configurations["port"].to_s
        unless port.match?(/\A\d+\z/) && port.to_i.between?(1, 65535)
          errors.add(:base, "IMAP Port must be a valid port number (1-65535)")
        end
      end
    end

    def validate_smtp_configurations
      if smtp_configurations.blank? || smtp_configurations["address"].blank?
        errors.add(:base, "SMTP Address is required when SMTP is enabled")
      elsif smtp_configurations["address"].match?(/\s/)
        errors.add(:base, "SMTP Address cannot contain spaces")
      end

      errors.add(:base, "SMTP Username is required when SMTP is enabled") if smtp_configurations.blank? || smtp_configurations["username"].blank?
      errors.add(:base, "SMTP Password is required when SMTP is enabled") if smtp_configurations.blank? || smtp_configurations["password"].blank?

      if smtp_configurations.present? && smtp_configurations["port"].present?
        port = smtp_configurations["port"].to_s
        unless port.match?(/\A\d+\z/) && port.to_i.between?(1, 65535)
          errors.add(:base, "SMTP Port must be a valid port number (1-65535)")
        end
      end
    end

    # Generate a forward email address:
    #   <slugified-channel-name>@<downcased-account-identifier>.helpbolic.com
    #
    # Example: "customer-support@acc7k3m2x0p.helpbolic.com"
    def generate_forward_email
      return if forward_email.present?

      slug = (name.presence || "inbox").parameterize
      domain = "#{account.identifier.downcase}.helpbolic.com"
      candidate = "#{slug}@#{domain}"
      counter = 1

      while Channel::Email.exists?(forward_email: candidate)
        counter += 1
        candidate = "#{slug}-#{counter}@#{domain}"
      end

      self.forward_email = candidate
    end

    # Register forward_email in GlobalRouting for inbound mail routing.
    # The Routable concern already registers `email` via routing_identifier.
    # This adds a second entry for the forward address.
    def register_forward_email_routing
      return if forward_email.blank?

      ActiveRecord::Base.connected_to(role: :writing) do
        routing = GlobalRouting.find_or_initialize_by(
          route_type: "forward_email",
          route_value: forward_email
        )
        routing.update!(
          account_id: account_id,
          shard_key: account.shard_key
        )
      end
    end

    def remove_forward_email_routing
      return if forward_email.blank?

      ActiveRecord::Base.connected_to(role: :writing) do
        GlobalRouting.where(
          route_type: "forward_email",
          route_value: forward_email
        ).delete_all
      end
    end
  end
end

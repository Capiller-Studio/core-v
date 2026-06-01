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
    include Routable
    belongs_to :account

    enum :status, { active: 0 }

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    # IMAP config: { address:, port:, username:, password:, enable_ssl: }
    def imap_enabled?
      imap_configurations.present? && imap_configurations["address"].present?
    end

    def imap_config
      @imap_config ||= imap_configurations.symbolize_keys
    end

    # SMTP config: { address:, port:, username:, password:, domain:, authentication:, enable_starttls: }
    def smtp_enabled?
      smtp_configurations.present? && smtp_configurations["address"].present?
    end

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
  end
end

# frozen_string_literal: true

module Auth
  class CertificateExpiryCheckerWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 3

    EXPIRY_THRESHOLDS = [30, 14, 7, 3, 1].freeze

    def perform
      Auth::SsoConfiguration.where(status: :active).where.not(certificate_expires_at: nil).find_each do |config|
        check_certificate_expiry(config)
      end
    end

    private

    def check_certificate_expiry(config)
      return if config.certificate_expires_at.blank?

      days_until_expiry = ((config.certificate_expires_at - Time.current) / 1.day).ceil
      return if days_until_expiry > 30

      Auth::AuditLog.log(
        event_type:    :certificate_warning,
        auth_method:   config.saml? ? :saml : :oidc,
        status:        :failure,
        account:       config.account,
        error_code:    "certificate_expiring",
        error_message: "Identity Provider certificate expires in #{days_until_expiry} day(s) on #{config.certificate_expires_at.strftime('%Y-%m-%d')}.",
        metadata:      {
          days_until_expiry:      days_until_expiry,
          certificate_expires_at: config.certificate_expires_at.iso8601
        }
      )

      # Trigger integration webhook for proactive notifications if account has shard
      if config.account.present?
        config.account.with_shard do
          Integrations::EventDispatcher.call(
            event_name: "sso.certificate_expiring",
            payload: {
              account_id:             config.account_id,
              days_until_expiry:      days_until_expiry,
              certificate_expires_at: config.certificate_expires_at.iso8601
            },
            account: config.account
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error("Auth::CertificateExpiryCheckerWorker error for account #{config.account_id}: #{e.message}")
    end
  end
end

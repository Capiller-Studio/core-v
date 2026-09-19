# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::CertificateExpiryCheckerWorker, type: :worker do
  let(:account) { create(:account) }

  describe "#perform" do
    subject(:perform_worker) { described_class.new.perform }

    context "when certificate is expiring within 30 days" do
      let!(:sso_config) do
        config = create(:auth_sso_configuration, account: account, status: :active)
        config.update_column(:certificate_expires_at, 10.days.from_now)
        config
      end

      it "logs a certificate_warning event in Auth::AuditLog" do
        expect { perform_worker }.to change(Auth::AuditLog, :count).by(1)

        log = Auth::AuditLog.last
        expect(log.event_type).to eq("certificate_warning")
        expect(log.account).to eq(account)
        expect(log.error_code).to eq("certificate_expiring")
        expect(log.error_message).to include("expires in")
      end

      it "dispatches an integration webhook event" do
        expect(Integrations::EventDispatcher).to receive(:call).with(
          event_name: "sso.certificate_expiring",
          payload: hash_including(
            account_id: account.id,
            days_until_expiry: 10
          ),
          account: account
        )

        perform_worker
      end
    end

    context "when certificate is valid for a long time (> 30 days)" do
      let!(:sso_config) do
        create(
          :auth_sso_configuration,
          account: account,
          status: :active,
          certificate_expires_at: 180.days.from_now
        )
      end

      it "does not log any warning or dispatch webhooks" do
        expect { perform_worker }.not_to change(Auth::AuditLog, :count)
        expect(Integrations::EventDispatcher).not_to receive(:call)
      end
    end

    context "when SSO configuration is inactive" do
      let!(:sso_config) do
        create(
          :auth_sso_configuration,
          account: account,
          status: :inactive,
          certificate_expires_at: 5.days.from_now
        )
      end

      it "does not process inactive configurations" do
        expect { perform_worker }.not_to change(Auth::AuditLog, :count)
      end
    end
  end
end

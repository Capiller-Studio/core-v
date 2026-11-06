# frozen_string_literal: true

require "rails_helper"
RSpec.describe Auth::AuditLog, type: :model do
  subject(:audit_log) { described_class.new }

  describe "Associations" do
    it { is_expected.to belong_to(:account).optional }
    it { is_expected.to belong_to(:user).optional }
  end

  describe "Enums" do
    it "defines event_type enum" do
      expect(audit_log).to define_enum_for(:event_type).with_values(
        login_attempt:         0,
        login_success:         1,
        login_failure:         2,
        logout:                3,
        jit_user_created:      4,
        identity_linked:       5,
        sso_config_changed:    6,
        domain_verified:       7,
        scim_user_created:     8,
        scim_user_updated:     9,
        scim_user_deactivated: 10,
        certificate_warning:   11,
        replay_attack_blocked: 12,
        bypass_login:          13
      )
    end

    it "defines auth_method enum" do
      expect(audit_log).to define_enum_for(:auth_method).with_values(
        password: 0,
        saml:     1,
        oidc:     2,
        google:   3,
        facebook: 4,
        github:   5,
        apple:    6,
        scim:     7
      )
    end

    it { is_expected.to define_enum_for(:status).with_values(success: 0, failure: 1) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:auth_method) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "Scopes" do
    let!(:success_log) { create(:auth_audit_log, status: :success, event_type: :login_success) }
    let!(:failure_log) { create(:auth_audit_log, :failure) }

    it "filters successes" do
      expect(described_class.successes).to contain_exactly(success_log)
    end

    it "filters failures" do
      expect(described_class.failures).to contain_exactly(failure_log)
    end

    it "filters by event_type" do
      expect(described_class.for_event(:login_failure)).to contain_exactly(failure_log)
    end
  end

  describe ".log factory" do
    let(:account) { create(:account) }
    let(:user)    { create(:user) }

    before do
      Current.ip_address = "10.0.0.1"
      Current.user_agent = "Capiller Rely-Client/1.0"
    end

    after do
      Current.reset
    end

    it "creates an audit log entry with explicit params" do
      log = described_class.log(
        event_type:    :login_success,
        auth_method:   :saml,
        status:        :success,
        account:       account,
        user:          user,
        email:         user.email,
        ip_address:    "1.2.3.4",
        user_agent:    "Custom-Agent",
        metadata:      { idp: "okta" }
      )

      expect(log).to be_persisted
      expect(log.event_type).to eq("login_success")
      expect(log.auth_method).to eq("saml")
      expect(log.status).to eq("success")
      expect(log.account).to eq(account)
      expect(log.user).to eq(user)
      expect(log.ip_address).to eq("1.2.3.4")
      expect(log.user_agent).to eq("Custom-Agent")
      expect(log.metadata).to eq({ "idp" => "okta" })
    end

    it "falls back to Current attributes when not explicitly provided" do
      Current.account = account
      Current.user = user

      log = described_class.log(
        event_type:  :login_success,
        auth_method: :saml,
        status:      :success
      )

      expect(log.account).to eq(account)
      expect(log.user).to eq(user)
      expect(log.ip_address).to eq("10.0.0.1")
      expect(log.user_agent).to eq("Capiller Rely-Client/1.0")
    end

    it "never raises an exception on invalid data, returning nil" do
      allow(described_class).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(described_class.new))

      expect do
        result = described_class.log(event_type: :login_success, auth_method: :saml, status: :success)
        expect(result).to be_nil
      end.not_to raise_error
    end
  end
end

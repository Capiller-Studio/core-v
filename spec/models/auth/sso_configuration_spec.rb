# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::SsoConfiguration, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "Enums" do
    it { is_expected.to define_enum_for(:protocol).with_values(saml: 0, oidc: 1) }
    it { is_expected.to define_enum_for(:provider_type).with_values(custom: 0, okta: 1, azure_ad: 2, google_workspace: 3, onelogin: 4, ping_identity: 5) }
    it { is_expected.to define_enum_for(:status).with_values(inactive: 0, active: 1, test_mode: 2) }
  end

  describe "Validations" do
    subject(:sso_config) { build(:auth_sso_configuration) }

    it { is_expected.to validate_presence_of(:protocol) }
    it { is_expected.to validate_presence_of(:provider_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:account_id).ignoring_case_sensitivity }

    context "when SAML protocol" do
      subject(:saml_config) { build(:auth_sso_configuration, protocol: :saml) }

      it { is_expected.to validate_presence_of(:idp_entity_id) }
      it { is_expected.to validate_presence_of(:idp_sso_url) }

      it "validates URL format of idp_sso_url" do
        saml_config.idp_sso_url = "not-a-url"
        expect(saml_config).not_to be_valid
        expect(saml_config.errors[:idp_sso_url]).to be_present
      end

      it "rejects invalid X.509 certificates" do
        saml_config.idp_certificates = ["invalid-cert-content"]
        expect(saml_config).not_to be_valid
        expect(saml_config.errors[:idp_certificates]).to be_present
      end

      it "accepts valid X.509 certificates" do
        saml_config.idp_certificates = [AuthTestCertificateHelper.generate_pem]
        expect(saml_config).to be_valid
      end
    end

    context "when OIDC protocol" do
      subject(:oidc_config) { build(:auth_sso_configuration, :oidc) }

      it { is_expected.to validate_presence_of(:oidc_issuer) }
      it { is_expected.to validate_presence_of(:oidc_client_id) }

      it "validates URL format of oidc_issuer" do
        oidc_config.oidc_issuer = "invalid-url"
        expect(oidc_config).not_to be_valid
        expect(oidc_config.errors[:oidc_issuer]).to be_present
      end
    end

    describe "allowed_email_domains" do
      it "rejects invalid domain formats" do
        config = build(:auth_sso_configuration, allowed_email_domains: ["invalid_domain", "@test.com"])
        expect(config).not_to be_valid
        expect(config.errors[:allowed_email_domains]).to be_present
      end

      it "normalizes domain names to lowercase" do
        config = create(:auth_sso_configuration, allowed_email_domains: ["  AcMeCorp.COM  "])
        expect(config.allowed_email_domains).to eq(["acmecorp.com"])
      end
    end
  end

  describe "Encryption" do
    it "encrypts oidc_client_secret at rest" do
      secret = "super-secret-oidc-key-12345"
      config = create(:auth_sso_configuration, :oidc, oidc_client_secret: secret)
      config.reload

      expect(config.oidc_client_secret).to eq(secret)
      raw_db_value = ActiveRecord::Base.connection.select_value(
        "SELECT oidc_client_secret FROM auth_sso_configurations WHERE id = '#{config.id}'"
      )
      expect(raw_db_value).not_to eq(secret)
      expect(raw_db_value).to include("{\"p\":")
    end
  end

  describe "Helper Methods" do
    let(:cert_pem) { AuthTestCertificateHelper.generate_pem(expires_in: 10.days) }
    let(:config) { create(:auth_sso_configuration, idp_certificates: [cert_pem], allowed_email_domains: ["acmecorp.com"]) }

    it "computes certificate_expires_at before save" do
      expect(config.certificate_expires_at).to be_present
      expect(config.certificate_expires_at).to be_within(5.minutes).of(10.days.from_now)
    end

    describe "#domain_matches?" do
      it "returns true for matching email" do
        expect(config.domain_matches?("alice@acmecorp.com")).to be true
      end

      it "returns true for matching domain string" do
        expect(config.domain_matches?("acmecorp.com")).to be true
      end

      it "returns false for non-matching domain" do
        expect(config.domain_matches?("alice@othercorp.com")).to be false
      end

      it "returns false for blank input" do
        expect(config.domain_matches?(nil)).to be false
        expect(config.domain_matches?("")).to be false
      end
    end

    describe "#certificate_expiring_soon?" do
      it "returns true when expiring within days window" do
        expect(config.certificate_expiring_soon?(days: 30)).to be true
      end

      it "returns false when expiry is further out than window" do
        expect(config.certificate_expiring_soon?(days: 5)).to be false
      end
    end

    describe "#certificate_fingerprints" do
      it "generates hex colon-separated fingerprints" do
        fingerprints = config.certificate_fingerprints
        expect(fingerprints).to be_an(Array)
        expect(fingerprints.first).to match(/\A([0-9a-f]{2}:){31}[0-9a-f]{2}\z/)
      end
    end
  end
end

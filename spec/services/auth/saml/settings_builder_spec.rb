# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::Saml::SettingsBuilder do
  let(:cert_pem) { AuthTestCertificateHelper.generate_pem }
  let(:account)  { create(:account, identifier: "acme") }
  let(:config) do
    create(
      :auth_sso_configuration,
      account:          account,
      idp_entity_id:    "http://www.okta.com/exk123",
      idp_sso_url:      "https://okta.com/app/sso",
      idp_slo_url:      "https://okta.com/app/slo",
      idp_certificates: [cert_pem]
    )
  end

  describe ".call" do
    it "configures IdP settings accurately" do
      settings = described_class.call(config)

      expect(settings.idp_entity_id).to eq("http://www.okta.com/exk123")
      expect(settings.idp_sso_service_url).to eq("https://okta.com/app/sso")
      expect(settings.idp_slo_service_url).to eq("https://okta.com/app/slo")
      expect(settings.idp_cert_multi[:signing]).to eq([cert_pem.strip])
    end

    it "derives SP URLs from request host when provided" do
      settings = described_class.call(config, "https://custom.helpdesk.io")

      expect(settings.sp_entity_id).to eq("https://custom.helpdesk.io/auth/saml/metadata")
      expect(settings.assertion_consumer_service_url).to eq("https://custom.helpdesk.io/auth/saml/consume")
      expect(settings.single_logout_service_url).to eq("https://custom.helpdesk.io/auth/saml/logout")
    end

    it "derives SP URLs from account identifier when host is omitted" do
      settings = described_class.call(config)

      expect(settings.sp_entity_id).to include("acme")
      expect(settings.assertion_consumer_service_url).to include("acme")
      expect(settings.assertion_consumer_service_url).to end_with("/auth/saml/consume")
    end

    it "sets security constraints to industry standard SHA-256" do
      settings = described_class.call(config)

      expect(settings.security[:want_assertions_signed]).to be true
      expect(settings.security[:signature_method]).to eq(XMLSecurity::Document::RSA_SHA256)
      expect(settings.security[:digest_method]).to eq(XMLSecurity::Document::SHA256)
    end
  end
end

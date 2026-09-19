# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::Saml::ResponseValidator do
  let(:cert_pem) { AuthTestCertificateHelper.generate_pem }
  let(:account)  { create(:account, identifier: "acme") }
  let(:config) do
    create(
      :auth_sso_configuration,
      account:          account,
      idp_entity_id:    "http://www.okta.com/exk123",
      idp_sso_url:      "https://okta.com/app/sso",
      idp_certificates: [cert_pem],
      attribute_mapping: { "first_name" => "custom_first", "last_name" => "custom_last" }
    )
  end

  describe ".call" do
    it "returns failure when raw_response is blank" do
      result = described_class.call(nil, config)
      expect(result).to be_failure
      expect(result.error_code).to eq("blank_response")
    end

    it "returns failure when response signature is invalid" do
      result = described_class.call("invalid-saml-response", config)
      expect(result).to be_failure
      expect(result.error_code).to be_present
    end

    context "with valid response simulation" do
      let(:mock_response) do
        instance_double(
          OneLogin::RubySaml::Response,
          is_valid?:        true,
          response_id:      "saml_response_12345",
          name_id:          "john.doe@acmecorp.com",
          not_on_or_after:  10.minutes.from_now,
          attributes:       OneLogin::RubySaml::Attributes.new(
            "custom_first" => ["John"],
            "custom_last"  => ["Doe"],
            "email"        => ["john.doe@acmecorp.com"],
            "groups"       => ["Admins", "Support"]
          )
        )
      end

      before do
        allow(OneLogin::RubySaml::Response).to receive(:new).and_return(mock_response)
        replay_key = RedisUtilities::Keys::AUTH_SAML_REPLAY % { response_id: "saml_response_12345" }
        RedisUtilities::Helpers.delete(replay_key)
      end

      after do
        replay_key = RedisUtilities::Keys::AUTH_SAML_REPLAY % { response_id: "saml_response_12345" }
        RedisUtilities::Helpers.delete(replay_key)
      end

      it "successfully validates and extracts attributes with mapping" do
        result = described_class.call("dummy_valid_xml", config)

        expect(result).to be_success
        expect(result.email).to eq("john.doe@acmecorp.com")
        expect(result.first_name).to eq("John")
        expect(result.last_name).to eq("Doe")
        expect(result.groups).to eq(["Admins", "Support"])
      end

      it "prevents replay attacks on duplicate response IDs" do
        first_call = described_class.call("dummy_valid_xml", config)
        expect(first_call).to be_success

        second_call = described_class.call("dummy_valid_xml", config)
        expect(second_call).to be_failure
        expect(second_call.error_code).to eq("replay_detected")

        audit_log = Auth::AuditLog.recent.first
        expect(audit_log.event_type).to eq("replay_attack_blocked")
        expect(audit_log.status).to eq("failure")
      end
    end
  end
end

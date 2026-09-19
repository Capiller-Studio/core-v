# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::DomainLookupService do
  let(:account) { create(:account, name: "Acme Corp", identifier: "acme") }
  let!(:config) do
    create(
      :auth_sso_configuration,
      account:               account,
      allowed_email_domains: ["acmecorp.com"],
      protocol:              :saml,
      provider_type:         :okta,
      status:                :active,
      enforce_sso:           true
    )
  end

  after do
    described_class.clear_cache("acmecorp.com")
    described_class.clear_cache("unknown.com")
  end

  describe ".call" do
    it "returns SSO details for a registered enterprise email" do
      result = described_class.call("john.doe@acmecorp.com")

      expect(result[:sso_required]).to be true
      expect(result[:account_id]).to eq(account.id)
      expect(result[:account_name]).to eq("Acme Corp")
      expect(result[:account_identifier]).to eq("acme")
      expect(result[:protocol]).to eq("saml")
      expect(result[:provider_type]).to eq("okta")
      expect(result[:enforce_sso]).to be true
    end

    it "returns SSO details when raw domain is queried" do
      result = described_class.call("acmecorp.com")
      expect(result[:sso_required]).to be true
      expect(result[:account_id]).to eq(account.id)
    end

    it "returns sso_required: false for unregistered domains" do
      result = described_class.call("alice@unknown.com")
      expect(result[:sso_required]).to be false
    end

    it "returns sso_required: false for blank inputs" do
      expect(described_class.call(nil)[:sso_required]).to be false
      expect(described_class.call("")[:sso_required]).to be false
    end

    it "caches lookup in Redis and avoids subsequent DB queries" do
      described_class.call("john@acmecorp.com")

      expect(Auth::SsoConfiguration).not_to receive(:joins)
      cached_result = described_class.call("other@acmecorp.com")
      expect(cached_result[:sso_required]).to be true
    end

    it "supports clearing cache" do
      described_class.call("john@acmecorp.com")
      cache_key = RedisUtilities::Keys::AUTH_DOMAIN_SSO % { domain: "acmecorp.com" }
      expect(RedisUtilities::Helpers.exists?(cache_key)).to be true

      described_class.clear_cache("acmecorp.com")
      expect(RedisUtilities::Helpers.exists?(cache_key)).to be false
    end
  end
end

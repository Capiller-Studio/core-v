# frozen_string_literal: true

require "openssl"

module AuthTestCertificateHelper
  def self.generate_pem(cn = "test.deskbolic.com", expires_in: 365.days)
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = SecureRandom.random_number(1_000_000)
    cert.subject = OpenSSL::X509::Name.parse("/CN=#{cn}")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.current - 1.day
    cert.not_after = Time.current + expires_in
    cert.sign(key, OpenSSL::Digest::SHA256.new)
    cert.to_pem
  end
end

FactoryBot.define do
  factory :auth_sso_configuration, class: "Auth::SsoConfiguration" do
    account
    protocol { :saml }
    provider_type { :okta }
    status { :active }
    idp_entity_id { "http://www.okta.com/exk#{SecureRandom.hex(4)}" }
    idp_sso_url { "https://dev-#{SecureRandom.hex(4)}.okta.com/app/sso/saml" }
    idp_certificates { [AuthTestCertificateHelper.generate_pem] }
    allowed_email_domains { ["acmecorp.com"] }
    enforce_sso { false }
    jit_provisioning_enabled { true }
    allow_owner_password_fallback { true }

    trait :oidc do
      protocol { :oidc }
      provider_type { :google_workspace }
      idp_entity_id { nil }
      idp_sso_url { nil }
      idp_certificates { [] }
      oidc_issuer { "https://accounts.google.com" }
      oidc_client_id { "google-client-id-#{SecureRandom.hex(8)}" }
      oidc_client_secret { "google-client-secret-#{SecureRandom.hex(16)}" }
    end

    trait :enforced do
      enforce_sso { true }
    end

    trait :test_mode do
      status { :test_mode }
    end
  end

  factory :auth_domain_verification, class: "Auth::DomainVerification" do
    account
    sequence(:domain) { |n| "company-#{n}.com" }
    status { :pending }
    check_count { 0 }

    trait :verified do
      status { :verified }
      verified_at { Time.current }
    end

    trait :failed do
      status { :failed }
      failure_reason { "TXT record not found" }
      check_count { 3 }
    end
  end

  factory :auth_user_identity, class: "Auth::UserIdentity" do
    user
    account
    provider { :saml }
    sequence(:uid) { |n| "user_#{n}@acmecorp.com" }
    sequence(:email) { |n| "user_#{n}@example.com" }
    credentials { {} }
    extra_attributes { { "first_name" => "John", "last_name" => "Doe" } }
    last_used_at { Time.current }

    trait :google do
      account { nil }
      provider { :google }
      sequence(:uid) { |n| "google_sub_#{n}" }
      sequence(:email) { |n| "user_#{n}@gmail.com" }
    end

    trait :facebook do
      account { nil }
      provider { :facebook }
      sequence(:uid) { |n| "facebook_id_#{n}" }
      sequence(:email) { |n| "user_#{n}@facebook.com" }
    end
  end

  factory :auth_scim_token, class: "Auth::ScimToken" do
    account
    name { "Okta SCIM Integration" }
    token_digest { Digest::SHA256.hexdigest("test_scim_token_#{SecureRandom.hex(16)}") }
    expires_at { 1.year.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end
  end

  factory :auth_audit_log, class: "Auth::AuditLog" do
    account
    user
    event_type { :login_success }
    auth_method { :saml }
    status { :success }
    email { user&.email || "agent@acmecorp.com" }
    ip_address { "192.168.1.1" }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" }
    metadata { { "idp_entity_id" => "http://www.okta.com/exk123" } }

    trait :failure do
      status { :failure }
      event_type { :login_failure }
      error_code { "invalid_signature" }
      error_message { "Signature validation failed" }
    end
  end
end

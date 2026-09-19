# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::DomainVerification, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "Enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, verified: 1, failed: 2) }
  end

  describe "Validations" do
    subject(:domain_verification) { build(:auth_domain_verification) }

    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:domain).case_insensitive }

    it "accepts valid domains" do
      %w[example.com my-company.org auth.subdomain.io].each do |d|
        domain_verification.domain = d
        expect(domain_verification).to be_valid
      end
    end

    it "rejects invalid domains" do
      %w[invalid_domain http://example.com example .com].each do |d|
        domain_verification.domain = d
        expect(domain_verification).not_to be_valid
        expect(domain_verification.errors[:domain]).to be_present
      end
    end
  end

  describe "Callbacks" do
    it "normalizes domain by stripping and lowercasing" do
      record = create(:auth_domain_verification, domain: "  ACME-Corp.COM  ")
      expect(record.domain).to eq("acme-corp.com")
    end

    it "generates a verification_token on creation" do
      record = create(:auth_domain_verification)
      expect(record.verification_token).to be_present
      expect(record.verification_token.length).to be >= 24
    end
  end

  describe "Methods" do
    let(:record) { create(:auth_domain_verification, domain: "acme.com") }

    it "#dns_txt_expected_value formats expected TXT record" do
      expect(record.dns_txt_expected_value).to eq("deskbolic-verify=#{record.verification_token}")
    end

    it "#dns_txt_record_host returns verification challenge host" do
      expect(record.dns_txt_record_host).to eq("_deskbolic-challenge.acme.com")
    end

    it "#mark_verified! updates status and timestamps" do
      record.mark_verified!
      expect(record.reload).to be_verified
      expect(record.verified_at).to be_present
      expect(record.failure_reason).to be_nil
    end

    it "#mark_failed! updates status, failure_reason, and increments check_count" do
      initial_count = record.check_count
      record.mark_failed!("DNS TXT record not found")
      expect(record.reload).to be_failed
      expect(record.failure_reason).to eq("DNS TXT record not found")
      expect(record.check_count).to eq(initial_count + 1)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::ScimToken, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "Validations" do
    subject { build(:auth_scim_token) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:token_digest) }
    it { is_expected.to validate_uniqueness_of(:token_digest) }
  end

  describe "Scopes" do
    let!(:active_token)  { create(:auth_scim_token, expires_at: 1.month.from_now) }
    let!(:never_expires) { create(:auth_scim_token, expires_at: nil) }
    let!(:expired_token) { create(:auth_scim_token, :expired) }

    it "active returns unexpired and non-expiring tokens" do
      expect(described_class.active).to contain_exactly(active_token, never_expires)
    end

    it "expired returns only expired tokens" do
      expect(described_class.expired).to contain_exactly(expired_token)
    end
  end

  describe ".generate_for_account" do
    let(:account) { create(:account) }

    it "creates a token record and returns raw bearer token" do
      record, raw_token = described_class.generate_for_account(account, name: "Okta Sync", expires_in: 30.days)

      expect(record).to be_persisted
      expect(record.account).to eq(account)
      expect(record.name).to eq("Okta Sync")
      expect(raw_token).to start_with("dbscim_")
      expect(record.token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(record.expires_at).to be_within(5.seconds).of(30.days.from_now)
    end
  end

  describe ".authenticate" do
    let(:account) { create(:account) }
    let!(:token_record_and_raw) { described_class.generate_for_account(account, name: "Test API") }
    let(:record) { token_record_and_raw.first }
    let(:raw_token) { token_record_and_raw.last }

    it "authenticates with valid raw token and updates last_used_at" do
      authenticated = described_class.authenticate(raw_token)
      expect(authenticated).to eq(record)
      expect(authenticated.last_used_at).to be_within(5.seconds).of(Time.current)
    end

    it "returns nil for incorrect token" do
      expect(described_class.authenticate("wrong-token")).to be_nil
    end

    it "returns nil for blank token" do
      expect(described_class.authenticate(nil)).to be_nil
      expect(described_class.authenticate("")).to be_nil
    end

    it "returns nil for expired token" do
      record.update!(expires_at: 1.day.ago)
      expect(described_class.authenticate(raw_token)).to be_nil
    end
  end
end

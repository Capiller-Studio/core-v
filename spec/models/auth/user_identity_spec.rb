# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::UserIdentity, type: :model do
  subject(:user_identity) { build(:auth_user_identity) }

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account).optional }
  end

  describe "Enums" do
    it "defines provider enum" do
      expect(user_identity).to define_enum_for(:provider).with_values(
        google: 0,
        facebook: 1,
        github: 2,
        apple: 3,
        saml: 4,
        oidc: 5
      )
    end
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:uid) }
    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }

    it "validates email format when present" do
      identity = build(:auth_user_identity, email: "invalid-email")
      expect(identity).not_to be_valid
      expect(identity.errors[:email]).to be_present

      identity.email = "valid@example.com"
      expect(identity).to be_valid
    end
  end

  describe "Scopes" do
    let!(:saml_id)   { create(:auth_user_identity, provider: :saml) }
    let!(:oidc_id)   { create(:auth_user_identity, provider: :oidc) }
    let!(:google_id) { create(:auth_user_identity, :google) }

    it "filters enterprise identities" do
      expect(described_class.for_enterprise).to contain_exactly(saml_id, oidc_id)
    end

    it "filters social identities" do
      expect(described_class.for_social).to contain_exactly(google_id)
    end
  end

  describe "Methods" do
    let(:saml_id)   { build(:auth_user_identity, provider: :saml) }
    let(:google_id) { build(:auth_user_identity, :google) }

    it "#enterprise? identifies SAML and OIDC" do
      expect(saml_id.enterprise?).to be true
      expect(google_id.enterprise?).to be false
    end

    it "#social? identifies social logins" do
      expect(google_id.social?).to be true
      expect(saml_id.social?).to be false
    end

    it "#touch_last_used! updates last_used_at timestamp" do
      record = create(:auth_user_identity, last_used_at: 1.day.ago)
      record.touch_last_used!
      expect(record.reload.last_used_at).to be_within(5.seconds).of(Time.current)
    end
  end
end

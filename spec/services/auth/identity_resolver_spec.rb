# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::IdentityResolver do
  let(:account) { create(:account) }
  let!(:sso_config) do
    create(
      :auth_sso_configuration,
      account:                  account,
      jit_provisioning_enabled: true
    )
  end

  describe ".call" do
    context "when identity already exists" do
      let!(:user) { create(:user, email: "existing.user@acmecorp.com") }
      let!(:identity) do
        create(
          :auth_user_identity,
          user:     user,
          account:  account,
          provider: :saml,
          uid:      "existing.user@acmecorp.com",
          email:    "existing.user@acmecorp.com"
        )
      end

      it "resolves existing user without creating records" do
        initial_user_count = User.count
        initial_id_count   = Auth::UserIdentity.count

        result = described_class.call(
          provider: :saml,
          uid:      "existing.user@acmecorp.com",
          email:    "existing.user@acmecorp.com",
          account:  account
        )

        expect(result).to be_success
        expect(result.user).to eq(user)
        expect(result.identity).to eq(identity)
        expect(result).not_to be_provisioned
        expect(User.count).to eq(initial_user_count)
        expect(Auth::UserIdentity.count).to eq(initial_id_count)
      end
    end

    context "when user exists by email but has no identity for this provider" do
      let!(:user) { create(:user, email: "john@acmecorp.com") }

      it "links new identity to existing user" do
        initial_user_count = User.count

        expect do
          result = described_class.call(
            provider: :saml,
            uid:      "okta_uid_999",
            email:    "john@acmecorp.com",
            account:  account
          )

          expect(result).to be_success
          expect(result.user).to eq(user)
          expect(result).not_to be_provisioned
          expect(user.auth_identities.find_by(provider: :saml, uid: "okta_uid_999")).to be_present
        end.to change(Auth::UserIdentity, :count).by(1)

        expect(User.count).to eq(initial_user_count)

        audit_log = Auth::AuditLog.recent.first
        expect(audit_log.event_type).to eq("identity_linked")
      end
    end

    context "when neither user nor identity exists (JIT Provisioning)" do
      it "provisions new user, address, identity, and account membership" do
        result = nil

        expect do
          result = described_class.call(
            provider:   :saml,
            uid:        "brand_new_user@acmecorp.com",
            email:      "brand_new_user@acmecorp.com",
            first_name: "Brand",
            last_name:  "New",
            account:    account
          )
        end.to change(User, :count).by(1)
           .and change(Auth::UserIdentity, :count).by(1)
           .and change(AccountUser, :count).by(1)

        expect(result).to be_success
        expect(result).to be_provisioned
        expect(result.user).to be_persisted
        expect(result.user.email).to eq("brand_new_user@acmecorp.com")
        expect(result.user.first_name).to eq("Brand")
        expect(result.user.last_name).to eq("New")
        expect(result.user.sso_provisioned?).to be true

        account_user = AccountUser.find_by(account: account, user: result.user)
        expect(account_user).to be_present
        expect(account_user.active?).to be true
        expect(account_user.owner?).to be false

        audit_log = Auth::AuditLog.recent.first
        expect(audit_log.event_type).to eq("jit_user_created")
      end

      it "fails when JIT provisioning is disabled" do
        sso_config.update!(jit_provisioning_enabled: false)

        result = described_class.call(
          provider: :saml,
          uid:      "blocked_user@acmecorp.com",
          email:    "blocked_user@acmecorp.com",
          account:  account
        )

        expect(result).to be_failure
        expect(result.error_code).to eq("jit_disabled")
      end
    end

    context "with social login (no account scoping)" do
      it "provisions user and global social identity without account membership" do
        initial_account_user_count = AccountUser.count
        result = nil

        expect do
          result = described_class.call(
            provider:   :google,
            uid:        "google_oauth_12345",
            email:      "social.user@gmail.com",
            first_name: "Social",
            last_name:  "User"
          )
        end.to change(User, :count).by(1)
           .and change(Auth::UserIdentity, :count).by(1)

        expect(result).to be_success
        expect(result).to be_provisioned
        expect(result.user.email).to eq("social.user@gmail.com")
        expect(result.identity.google?).to be true
        expect(result.identity.account).to be_nil
        expect(AccountUser.count).to eq(initial_account_user_count)
      end
    end
  end
end

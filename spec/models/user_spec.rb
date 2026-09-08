require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'Associations' do
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:accounts).through(:account_users) }
    it { is_expected.to have_many(:team_users).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:team_users) }
    it { is_expected.to have_one(:affiliate_profile).dependent(:destroy) }
    it { is_expected.to belong_to(:address) }
    
    it { is_expected.to have_many(:user_skills).dependent(:destroy) }
    it { is_expected.to have_many(:skills).through(:user_skills) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:access_tokens).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, pending_deletion: 1, deleted: 2) }
    it { is_expected.to define_enum_for(:gender).with_values(male: 0, female: 1) }
  end

  describe 'Callbacks' do
    it 'configures display_name before save' do
      user = build(:user, first_name: 'John', middle_name: 'M.', last_name: 'Doe')
      user.save!
      expect(user.display_name).to eq('John M. Doe')
    end

    it 'generates a connection_token automatically' do
      user = create(:user)
      expect(user.connection_token).to be_present
    end
  end

  describe '#event_payload' do
    let(:user) { create(:user, first_name: 'Jane', last_name: 'Smith') }

    it 'returns the basic user data' do
      payload = user.event_payload
      expect(payload[:id]).to eq(user.id)
      expect(payload[:name]).to eq(user.name)
      expect(payload[:display_name]).to eq('Jane Smith')
    end

    it 'includes avatar_url if avatar is attached' do
      user.avatar.attach(io: StringIO.new('dummy'), filename: 'avatar.png', content_type: 'image/png')
      payload = user.event_payload
      expect(payload[:avatar_url]).to be_present
    end
  end

  describe '#send_devise_notification' do
    it 'sends the devise notification in the background' do
      user = create(:user)
      expect {
        user.send_devise_notification(:reset_password_instructions, 'token')
      }.to have_enqueued_job
    end
  end

  describe '#can_be_deleted?' do
    let(:user) { create(:user) }
    let(:account) { create(:account) }

    it 'returns true if user is not an owner of any active account' do
      create(:account_user, account: account, user: user, owner: false)
      expect(user.can_be_deleted?).to be true
    end

    it 'returns false if user is the owner of an active account' do
      create(:account_user, account: account, user: user, owner: true)
      expect(user.can_be_deleted?).to be false
    end

    it 'returns true if user owns an account that is already pending_deletion or deleted' do
      create(:account_user, account: account, user: user, owner: true)
      account.update_column(:status, Account.statuses[:pending_deletion])
      expect(user.can_be_deleted?).to be true
    end
  end

  describe 'Soft Deletion & Restoration' do
    let(:user) { create(:user, email: 'john.doe@example.com', username: 'johndoe', confirmed_at: Time.current) }
    let(:account) { create(:account) }
    let!(:account_user) { create(:account_user, account: account, user: user, owner: false) }

    it 'deactivates user, marks account_users pending_deletion, and sets deletion metadata' do
      user.deactivate_for_deletion!

      expect(user.reload).to be_pending_deletion
      expect(user.data['deletion']['requested_at']).to be_present
      expect(account_user.reload).to be_pending_deletion
      expect(user.active_for_authentication?).to be false
    end

    it 'revokes access tokens and cleans up notification subscriptions on deactivation' do
      create(:access_token, owner: user)
      ShardRecord.connected_to(shard: :de, role: :writing) do
        create(:notification_subscription, user: user)
      end

      expect(user.access_tokens.count).to eq(1)

      user.deactivate_for_deletion!

      expect(user.access_tokens.count).to eq(0)
      ShardRecord.connected_to(shard: :de, role: :writing) do
        expect(NotificationSubscription.where(user_id: user.id).count).to eq(0)
      end
    end

    it 'marks user as deleted, vaults identity, nullifies email and username' do
      orig_email = user.email
      orig_username = user.username

      user.deactivate_for_deletion!
      user.mark_as_deleted!

      expect(user.reload).to be_deleted
      expect(user.email).to be_nil
      expect(user.username).to be_nil
      expect(user.data['archived_identity']['email']).to eq(orig_email)
      expect(user.data['archived_identity']['username']).to eq(orig_username)
      expect(account_user.reload).to be_deleted
      expect(user.active_for_authentication?).to be false
    end

    describe 'Devise and authentication overrides when deleted' do
      it 'does not require email or password once deleted' do
        user.deactivate_for_deletion!
        user.mark_as_deleted!

        expect(user.email_required?).to be false
        expect(user.password_required?).to be false
      end

      it 'returns custom inactive_message for pending_deletion and deleted states' do
        user.deactivate_for_deletion!
        expect(user.inactive_message).to eq(:deletion_requested)

        user.mark_as_deleted!
        expect(user.inactive_message).to eq(:deleted)
      end
    end

    it 'restores user back to active status and restores identity without reconfirmation' do
      orig_email = user.email
      user.deactivate_for_deletion!
      user.mark_as_deleted!

      expect(user).to receive(:before_restore_active).and_call_original
      user.restore_active!

      expect(user.reload).to be_active
      expect(user.email).to eq(orig_email)
      expect(user.unconfirmed_email).to be_nil
      expect(account_user.reload).to be_active
      expect(user.active_for_authentication?).to be true
    end

    it 'only restores account_users belonging to active accounts' do
      deleted_account = create(:account, status: :deleted)
      deleted_account_user = create(:account_user, account: deleted_account, user: user, status: :deleted)

      user.deactivate_for_deletion!
      user.mark_as_deleted!

      user.restore_active!

      expect(account_user.reload).to be_active
      expect(deleted_account_user.reload).to be_deleted
    end

    it 'prevents restoring if email is taken by another active user' do
      orig_email = user.email
      user.deactivate_for_deletion!
      user.mark_as_deleted!

      create(:user, email: orig_email)

      expect { user.restore_active! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(user.reload).to be_deleted
    end
  end
end


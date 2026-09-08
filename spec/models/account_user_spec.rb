require 'rails_helper'

RSpec.describe AccountUser, type: :model do
  subject { build(:account_user) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:invited_by).class_name('User').optional }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:availability).with_values(online: 0, offline: 1) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, pending_deletion: 1, deleted: 2) }
  end

  describe 'Validations' do
    it 'enforces user limit on create' do
      account = create(:account)
      user = create(:user)

      # Mock the limit check
      allow(account).to receive(:within_limit?).with(:users).and_return(false)

      account_user = build(:account_user, account: account, user: user)
      expect(account_user.save).to be false
      expect(account_user.errors[:base]).to include("User limit reached for your plan. Please upgrade.")
    end
  end

  describe 'Callbacks' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }

    it 'increments usage on agent added' do
      # We need to make sure within_limit? returns true so it can be created
      allow(account).to receive(:within_limit?).with(:users).and_return(true)

      allow(account).to receive(:increment_usage!)
      allow(account).to receive(:track_agent_count!)
      create(:account_user, account: account, user: user)
      expect(account).to have_received(:increment_usage!).with(:users)
      expect(account).to have_received(:track_agent_count!)
    end

    it 'decrements usage on agent removed' do
      # Avoid the limit check for creation
      allow(account).to receive(:within_limit?).with(:users).and_return(true)

      account_user = create(:account_user, account: account, user: user)

      allow(account).to receive(:decrement_usage!)
      account_user.destroy
      expect(account).to have_received(:decrement_usage!).with(:users)
    end
  end

  describe 'Owner Protections' do
    let(:account) { create(:account) }

    it 'prevents owner from being removed from owner status' do
      owner = create(:account_user, account: account, user: create(:user), owner: true)
      owner.owner = false
      expect(owner.save).to be false
      expect(owner.errors[:owner]).to include("cannot be removed from the account owner")
    end

    it 'prevents creating a second owner for the same account' do
      create(:account_user, account: account, user: create(:user), owner: true)
      second_owner = build(:account_user, account: account, user: create(:user), owner: true)
      
      expect(second_owner.save).to be false
      expect(second_owner.errors[:owner]).to include("an owner already exists for this account")
    end

    it 'prevents the owner from being deleted' do
      owner = create(:account_user, account: account, user: create(:user), owner: true)
      expect(owner.destroy).to be false
      expect(owner.errors[:base]).to include("Account owner cannot be removed")
    end
  end
end

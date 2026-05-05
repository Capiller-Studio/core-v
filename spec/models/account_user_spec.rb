require 'rails_helper'

RSpec.describe AccountUser, type: :model do
  subject { build(:account_user) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:invited_by).class_name('User').optional }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:role).with_values(owner: 0, agent: 1, admin: 2) }
    it { is_expected.to define_enum_for(:availability).with_values(online: 0, offline: 1) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
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
      allow_any_instance_of(Account).to receive(:within_limit?).with(:users).and_return(true)
      
      expect_any_instance_of(Account).to receive(:increment_usage!).with(:users)
      create(:account_user, account: account, user: user)
    end

    it 'decrements usage on agent removed' do
      # Avoid the limit check for creation
      allow_any_instance_of(Account).to receive(:within_limit?).with(:users).and_return(true)
      
      account_user = create(:account_user, account: account, user: user)
      
      expect(account).to receive(:decrement_usage!).with(:users)
      account_user.destroy
    end
  end
end

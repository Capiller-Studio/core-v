require 'rails_helper'

RSpec.describe Account, type: :model do
  subject { build(:account) }

  describe 'Associations' do
    it { is_expected.to have_many(:customers).dependent(:destroy) }
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:account_users) }
    it { is_expected.to have_many(:conversations).dependent(:destroy) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:email_templates).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:roles).class_name('Access::Role').dependent(:destroy) }
    it { is_expected.to have_many(:identity_sources).dependent(:destroy) }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
    it { is_expected.to have_many(:inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:portals).class_name('HelpCenter::Portal').dependent(:destroy) }
    it { is_expected.to have_many(:teams).dependent(:destroy) }
    it { is_expected.to have_many(:labels).dependent(:destroy) }
    it { is_expected.to have_many(:canned_responses).dependent(:destroy) }
    it { is_expected.to have_many(:automations).dependent(:destroy) }
    it { is_expected.to have_many(:automation_executions).dependent(:destroy) }
    it { is_expected.to have_many(:integrations).dependent(:destroy) }
    
    # Billable associations
    it { is_expected.to have_one(:wallet).dependent(:destroy) }
    it { is_expected.to have_many(:subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:payment_methods).dependent(:destroy) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
    it { is_expected.to define_enum_for(:referral_commission_type).with_values(fixed: 0) }
  end

  describe 'Callbacks' do
    it 'generates default roles after create' do
      account = build(:account)
      expect(Access::RoleGenerator).to receive(:call).with(account)
      account.save!
    end

    it 'creates a wallet after create' do
      account = create(:account)
      expect(account.wallet).to be_present
    end
  end

  describe 'Code Generation' do
    it 'generates identifier before validation' do
      account = build(:account, identifier: nil)
      account.validate
      expect(account.identifier).to start_with('ACC')
    end

    it 'generates referral_code before validation' do
      account = build(:account, referral_code: nil)
      account.validate
      expect(account.referral_code).to be_present
    end
  end

  describe '#feature_enabled?' do
    let(:account) { create(:account) }
    
    context 'when manually enabled via bitmask' do
      it 'returns true when teams_enabled? is true' do
        account.teams_enabled = true
        expect(account.feature_enabled?(:teams)).to be true
      end

      it 'returns true when checking with _enabled suffix' do
        account.teams_enabled = true
        expect(account.feature_enabled?(:teams_enabled)).to be true
      end
    end

    context 'when falling back to plan' do
      let(:plan) { instance_double('Plan') }

      before do
        allow(account).to receive(:current_plan).and_return(plan)
        account.teams_enabled = false
      end

      it 'returns true if plan configuration is true' do
        allow(plan).to receive(:feature_enabled?).with('teams').and_return(true)
        expect(account.feature_enabled?(:teams)).to be true
      end

      it 'returns false if plan configuration is false' do
        allow(plan).to receive(:feature_enabled?).with('teams').and_return(false)
        expect(account.feature_enabled?(:teams)).to be false
      end
    end
  end

  describe 'Limit Enforcing' do
    let(:account) { create(:account) }

    it 'returns current usage from limits jsonb' do
      account.update_column(:limits, { 'users' => { 'current' => 5 } })
      expect(account.current_usage(:users)).to eq(5)
    end

    it 'increments usage correctly' do
      expect {
        account.increment_usage!(:users)
      }.to change { account.current_usage(:users) }.by(1)
    end

    it 'decrements usage correctly' do
      account.increment_usage!(:users)
      expect {
        account.decrement_usage!(:users)
      }.to change { account.current_usage(:users) }.by(-1)
    end
  end
end

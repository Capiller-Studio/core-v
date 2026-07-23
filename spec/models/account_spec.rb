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
    it { is_expected.to define_enum_for(:status).with_values(active: 0, suspended: 1) }
    it { is_expected.to define_enum_for(:referral_commission_type).with_values(fixed: 0) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:timezone) }
    it { is_expected.to validate_inclusion_of(:timezone).in_array(ActiveSupport::TimeZone.all.map(&:name)) }
  end

  describe 'Callbacks' do
    it 'generates default roles after create' do
      account = build(:account)
      allow(Access::RoleGenerator).to receive(:call)
      account.save!
      expect(Access::RoleGenerator).to have_received(:call).with(account)
    end

    it 'generates default custom fields after create' do
      account = build(:account)
      allow(Accounts::DefaultCustomFieldsCreator).to receive(:call)
      account.save!
      expect(Accounts::DefaultCustomFieldsCreator).to have_received(:call).with(account: account)
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

  describe '#users_count' do
    it 'delegates to current_usage(:users)' do
      account = build(:account)
      allow(account).to receive(:current_usage).with(:users).and_return(3)
      expect(account.users_count).to eq(3)
    end
  end

  describe '#event_payload' do
    it 'returns the expected hash' do
      account = create(:account, name: 'Acme Corp')
      expect(account.event_payload).to eq({
        id: account.id,
        name: 'Acme Corp',
        type: 'Account'
      })
    end
  end

  describe '#feature_enabled?' do
    let(:account) { create(:account) }

    context 'when falling back to plan' do
      let(:plan) { instance_double(Plan) }

      before do
        allow(account).to receive(:current_plan).and_return(plan)
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
      # rubocop:disable Rails/SkipsModelValidations
      account.update_column(:limits, { 'users' => { 'current' => 5 } })
      # rubocop:enable Rails/SkipsModelValidations
      expect(account.current_usage(:users)).to eq(5)
    end

    it 'increments usage on agent added' do
      # We need to make sure within_limit? returns true so it can be created
      allow(account).to receive(:within_limit?).with(:users).and_return(true)

      allow(account).to receive(:increment_usage!)
      create(:account_user, account: account, user: create(:user))
      expect(account).to have_received(:increment_usage!).with(:users)
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

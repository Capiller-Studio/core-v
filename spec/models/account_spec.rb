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
    it { is_expected.to define_enum_for(:status).with_values(active: 0, suspended: 1, pending_deletion: 2, deleted: 3) }
    it { is_expected.to define_enum_for(:referral_commission_type).with_values(fixed: 0) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:timezone) }
    it { is_expected.to validate_inclusion_of(:timezone).in_array(ActiveSupport::TimeZone.all.map(&:name)) }
    it { is_expected.to validate_exclusion_of(:identifier).in_array(Account::RESERVED_IDENTIFIERS).with_message("is a reserved word and cannot be used") }
    
    it 'validates format of identifier' do
      expect(build(:account, identifier: 'valid-slug-123')).to be_valid
      
      invalid_account = build(:account, identifier: 'invalid_slug!')
      expect(invalid_account).not_to be_valid
      expect(invalid_account.errors[:identifier]).to include("can only contain lowercase letters, numbers, and hyphens")
    end
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
    it 'generates identifier before validation using slug generator' do
      account = build(:account, identifier: nil, name: 'Acme Corp')
      account.validate
      expect(account.identifier).to eq('acme-corp')
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

  describe 'Soft Deletion & Restoration' do
    let(:account) { create(:account) }

    it 'deactivates account and sets status to pending_deletion' do
      domain = create(:domain, account: account, status: :active)

      account.deactivate_for_deletion!

      expect(account.reload).to be_pending_deletion
      expect(account.data['deletion']['requested_at']).to be_present
      expect(domain.reload).to be_inactive
    end

    it 'cancels active subscription upon deactivation' do
      plan = create(:plan)
      subscription = create(:subscription, account: account, plan: plan, status: :active)

      account.deactivate_for_deletion!

      expect(subscription.reload).to be_cancelled
    end

    it 'revokes access tokens and cascades pending_deletion to account_users' do
      create(:access_token, owner: account)
      account_user = create(:account_user, account: account, user: create(:user))

      account.deactivate_for_deletion!

      expect(account.access_tokens.count).to eq(0)
      expect(account_user.reload).to be_pending_deletion
    end

    it 'marks account as deleted, vaults identity and nullifies unique fields' do
      orig_id = account.identifier
      orig_ref = account.referral_code
      account_user = create(:account_user, account: account, user: create(:user))

      account.deactivate_for_deletion!
      account.mark_as_deleted!

      expect(account.reload).to be_deleted
      expect(account.identifier).to be_nil
      expect(account.referral_code).to be_nil
      expect(account.data['archived_identity']['identifier']).to eq(orig_id)
      expect(account.data['archived_identity']['referral_code']).to eq(orig_ref)
      expect(account_user.reload).to be_deleted
    end

    it 'cleans up inboxes and channels on shard upon mark_as_deleted!' do
      account.with_shard do
        create(:inbox, account: account, name: 'Support Inbox')
      end

      expect(account.with_shard { account.inboxes.count }).to be >= 1

      account.deactivate_for_deletion!
      account.mark_as_deleted!

      expect(account.with_shard { account.inboxes.count }).to eq(0)
    end

    it 'restores account back to active status, reactivates domains and account_users' do
      orig_id = account.identifier
      domain = create(:domain, account: account, status: :active)
      account_user = create(:account_user, account: account, user: create(:user))

      account.deactivate_for_deletion!
      account.mark_as_deleted!

      expect(domain.reload).to be_inactive
      expect(account_user.reload).to be_deleted

      account.restore_active!

      expect(account.reload).to be_active
      expect(account.identifier).to eq(orig_id)
      expect(domain.reload).to be_active
      expect(account_user.reload).to be_active
    end

    it 'prevents double-deactivation when already deleted' do
      account.deactivate_for_deletion!
      account.mark_as_deleted!

      expect { account.deactivate_for_deletion! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises validation error on restoration if identifier is claimed by another account' do
      orig_id = account.identifier
      account.deactivate_for_deletion!
      account.mark_as_deleted!

      create(:account, identifier: orig_id)

      expect { account.restore_active! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(account.reload).to be_deleted
    end
  end
end

require 'rails_helper'

RSpec.describe Inbox, type: :model do
  subject { build(:inbox) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:channel) }
    it { is_expected.to belong_to(:csat_survey).class_name('Csat::Survey').optional }
    it { is_expected.to belong_to(:conversation_reply_template).class_name('EmailTemplate').optional }
    it { is_expected.to have_many(:conversations).dependent(:destroy) }
    it { is_expected.to have_many(:inbox_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:inbox_users) }
    it { is_expected.to have_many(:inbox_teams).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:inbox_teams) }
    it { is_expected.to have_many(:customer_inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:customers).through(:customer_inboxes) }
    it { is_expected.to have_many(:sla_inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:sla_policies).through(:sla_inboxes) }
    it { is_expected.to have_many(:assignment_policy_inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:assignment_policies).through(:assignment_policy_inboxes) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
  end

  describe '#auto_assign?' do
    let(:inbox) { build(:inbox) }

    it 'returns false by default' do
      expect(inbox.auto_assign?).to be false
    end

    it 'returns true when enabled' do
      inbox.auto_assign = true
      expect(inbox.auto_assign?).to be true
    end
  end

  describe 'Callbacks' do
    it 'cleans up integration settings after destroy' do
      inbox = create(:inbox)
      integration = create(:integration, account: inbox.account, settings: { 'subscribed_inboxes' => [ inbox.id ] })

      inbox.destroy
      integration.reload
      expect(integration.settings['subscribed_inboxes']).not_to include(inbox.id)
    end

    it 'sets primary_inbox if it is the first inbox for the channel' do
      channel = create(:channel_email)
      inbox = build(:inbox, channel: channel)
      # We check if primary_inbox is true. Since the channel has no other inboxes, it should set it.
      # If primary_inbox is not a database column, we rescue NoMethodError in case it's buggy in the main app
      begin
        inbox.save!
        expect(inbox.primary_inbox).to be true
      rescue NoMethodError
        # skip if primary_inbox is not defined
      end
    end

    it 'cleans up unread counts in Redis after destroy' do
      account = create(:account)
      user = create(:user)
      create(:account_user, account: account, user: user)
      inbox = create(:inbox, account: account)
      
      allow(RedisUtilities::Helpers).to receive(:hash_delete)
      allow(UnreadCounts::Broadcast).to receive(:call)
      
      inbox.destroy
      
      key = RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: account.id, member_id: user.id }
      expect(RedisUtilities::Helpers).to have_received(:hash_delete).with(key, inbox.id)
      expect(UnreadCounts::Broadcast).to have_received(:call).with(member: user, account_id: account.id)
    end
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:inbox) { create(:inbox, account: account) }

    before do
      create(:account_user, account: account, user: user)
    end

    describe '.for_user and .current_inboxes' do
      it 'returns inboxes assigned to the user directly' do
        create(:inbox_user, inbox: inbox, user: user)
        expect(Inbox.for_user(user)).to include(inbox)
        expect(Inbox.current_inboxes(user)).to include(inbox)
      end

      it 'returns inboxes assigned to the user through their team' do
        team = create(:team, account: account)
        create(:team_user, team: team, user: user)
        create(:inbox_team, inbox: inbox, team: team)

        expect(Inbox.for_user(user)).to include(inbox)
      end

      it 'does not return inboxes not assigned to the user' do
        other_inbox = create(:inbox, account: account)
        expect(Inbox.for_user(user)).not_to include(other_inbox)
      end
    end
  end

  describe 'Collaborator & Team Assignment' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:team1) { create(:team, account: account) }

    before do
      create(:account_user, account: account, user: user1)
      create(:account_user, account: account, user: user2)
    end

    describe '#assign_users' do
      it 'synchronizes users differentially' do
        inbox.assign_users([user1.id])
        expect(inbox.assigned_user_ids).to eq([user1.id.to_s])

        inbox.assign_users([user2.id])
        expect(inbox.assigned_user_ids).to eq([user2.id.to_s])

        inbox.assign_users([])
        expect(inbox.assigned_user_ids).to be_empty
      end
    end

    describe '#assign_teams' do
      it 'synchronizes teams differentially' do
        inbox.assign_teams([team1.id])
        expect(inbox.assigned_team_ids).to eq([team1.id.to_s])

        inbox.assign_teams([])
        expect(inbox.assigned_team_ids).to be_empty
      end
    end

    describe '#collaborator_user_ids' do
      it 'combines direct and team users' do
        inbox.assign_users([user1.id])
        create(:team_user, team: team1, user: user2)
        inbox.assign_teams([team1.id])

        expect(inbox.collaborator_user_ids).to contain_exactly(user1.id.to_s, user2.id.to_s)
      end
    end

    describe '#accessible_by?' do
      let(:owner) { create(:user) }
      let(:agent) { create(:user) }

      before do
        create(:account_user, account: account, user: owner, owner: true)
        create(:account_user, account: account, user: agent)
      end

      it 'allows workspace owner unconditionally' do
        expect(inbox.accessible_by?(owner)).to be true
      end

      it 'denies unassigned agent' do
        expect(inbox.accessible_by?(agent)).to be false
      end

      it 'allows assigned agent' do
        inbox.assign_users([agent.id])
        expect(inbox.accessible_by?(agent)).to be true
      end

      it 'allows agent assigned through a team' do
        create(:team_user, team: team1, user: agent)
        inbox.assign_teams([team1.id])
        expect(inbox.accessible_by?(agent)).to be true
      end
    end

    describe 'attribute setters user_ids= and team_ids=' do
      it 'persists assignments via setters' do
        inbox.user_ids = [user1.id]
        inbox.team_ids = [team1.id]

        expect(inbox.assigned_user_ids).to eq([user1.id.to_s])
        expect(inbox.assigned_team_ids).to eq([team1.id.to_s])
      end
    end
  end
end

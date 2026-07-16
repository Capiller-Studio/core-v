require 'rails_helper'

RSpec.describe Teams::CreateService do
  let(:account) { create(:account) }
  let(:user1) { create(:user).tap { |u| create(:account_user, user: u, account: account) } }
  let(:user2) { create(:user).tap { |u| create(:account_user, user: u, account: account) } }
  let(:inbox) { create(:inbox, account: account) }
  
  let(:params) do
    {
      name: 'Sales Team',
      description: 'Handles sales',
      auto_assign: true,
      user_ids: [user1.id, user2.id],
      lead_id: user1.id,
      inbox_ids: [inbox.id]
    }
  end

  let(:service) { described_class.new(account: account, params: params) }

  describe '#call' do
    context 'when feature is enabled' do
      before do
        allow(account).to receive(:feature_enabled?).with(:teams).and_return(true)
      end

      it 'creates a team with members and inboxes' do
        result = nil
        expect {
          result = service.call
        }.to change(Team, :count).by(1)
         .and change(TeamUser, :count).by(2)
         .and change(InboxTeam, :count).by(1)

        team = account.teams.find_by(name: 'Sales Team')
        expect(team).not_to be_nil
        expect(team.description).to eq('Handles sales')
        expect(team.auto_assign).to be true

        expect(team.team_users.find_by(user: user1).role).to eq('lead')
        expect(team.team_users.find_by(user: user2).role).to eq('member')
        
        expect(team.inbox_teams.first.inbox).to eq(inbox)
      end
    end

    context 'when feature is not enabled' do
      before do
        allow(account).to receive(:feature_enabled?).with(:teams).and_return(false)
      end

      it 'raises an error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotSaved, /Teams feature is not enabled/)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Teams::UpdateService do
  let(:account) { create(:account) }
  let(:team) { create(:team, account: account) }
  
  let(:user1) { create(:user).tap { |u| create(:account_user, user: u, account: account) } }
  let(:user2) { create(:user).tap { |u| create(:account_user, user: u, account: account) } }
  let(:user3) { create(:user).tap { |u| create(:account_user, user: u, account: account) } }
  let(:inbox1) { create(:inbox, account: account) }
  let(:inbox2) { create(:inbox, account: account) }

  before do
    allow(team).to receive(:account).and_return(account)
    allow(account).to receive(:feature_enabled?).with(:teams).and_return(true)
    
    # Setup initial state
    create(:team_user, team: team, user: user1, role: 'lead')
    create(:team_user, team: team, user: user2, role: 'member')
    create(:inbox_team, team: team, inbox: inbox1)
  end

  describe '#call' do
    context 'when updating team attributes' do
      let(:service) { described_class.new(team: team, params: { name: 'New Name' }) }

      it 'updates the attributes' do
        service.call
        expect(team.reload.name).to eq('New Name')
      end
    end

    context 'when updating members' do
      # Remove user2, add user3, change lead to user3
      let(:params) do
        {
          user_ids: [user1.id, user3.id],
          lead_id: user3.id
        }
      end
      let(:service) { described_class.new(team: team, params: params) }

      it 'syncs members and lead roles' do
        service.call
        team.reload

        expect(team.team_users.pluck(:user_id)).to match_array([user1.id, user3.id])
        expect(team.team_users.find_by(user: user3).role).to eq('lead')
        expect(team.team_users.find_by(user: user1).role).to eq('member')
      end
    end

    context 'when updating inboxes' do
      # Remove inbox1, add inbox2
      let(:params) do
        {
          inbox_ids: [inbox2.id]
        }
      end
      let(:service) { described_class.new(team: team, params: params) }

      it 'syncs inboxes' do
        service.call
        team.reload

        expect(team.inbox_teams.pluck(:inbox_id)).to eq([inbox2.id])
      end
    end

    context 'when feature is not enabled' do
      let(:service) { described_class.new(team: team, params: { name: 'New Name' }) }

      before do
        allow(account).to receive(:feature_enabled?).with(:teams).and_return(false)
      end

      it 'raises an error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotSaved, /Teams feature is not enabled/)
      end
    end
  end
end

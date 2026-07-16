require 'rails_helper'

RSpec.describe Teams::MemberService do
  let(:account) { create(:account) }
  let(:team) { create(:team, account: account) }
  let(:user) { create(:user).tap { |u| create(:account_user, user: u, account: account) } }

  describe '#call' do
    context 'when action is :add' do
      let(:service) { described_class.new(team: team, params: { action: 'add', user_id: user.id, role: 'lead' }) }

      it 'adds the member to the team with the specified role' do
        expect { service.call }.to change(TeamUser, :count).by(1)
        team_user = team.team_users.find_by(user_id: user.id)
        expect(team_user).not_to be_nil
        expect(team_user.role).to eq('lead')
      end
    end

    context 'when action is :remove' do
      let(:service) { described_class.new(team: team, params: { action: 'remove', user_id: user.id }) }

      before { create(:team_user, team: team, user: user) }

      it 'removes the member from the team' do
        expect { service.call }.to change(TeamUser, :count).by(-1)
      end
    end

    context 'when action is :update_role' do
      let(:service) { described_class.new(team: team, params: { action: 'update_role', user_id: user.id, role: 'lead' }) }

      before { create(:team_user, team: team, user: user, role: 'member') }

      it 'updates the role of the member' do
        service.call
        expect(TeamUser.find_by(team: team, user: user).role).to eq('lead')
      end
    end

    context 'when action is unknown' do
      let(:service) { described_class.new(team: team, params: { action: 'foo' }) }

      it 'raises an ArgumentError' do
        expect { service.call }.to raise_error(ArgumentError, /Unknown action/)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Teams::AssignmentService do
  let(:account) { create(:account) }
  let(:team) { create(:team, account: account) }
  let(:agent) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    create(:account_user, user: agent, account: account)
  end

  describe '#call' do
    context 'when assigning a team' do
      let(:service) { described_class.new(conversation: conversation, team: team) }

      it 'assigns the team and notifies team leads' do
        lead = create(:user)
        create(:account_user, user: lead, account: account)
        create(:team_user, team: team, user: lead, role: 'lead')
        
        expect { service.call }.to change { Notification.where(event: 'team_assigned', user: lead).count }.by_at_least(1)
        
        expect(conversation.reload.team).to eq(team)
        
        notification = Notification.where(event: 'team_assigned', user: lead).last
        expect(notification).not_to be_nil
        expect(notification.resource).to eq(conversation)
      end
    end

    context 'when unassigning a team' do
      let(:service) { described_class.new(conversation: conversation, team: nil) }

      before { conversation.update!(team: team) }

      it 'unassigns the team' do
        service.call
        expect(conversation.reload.team).to be_nil
      end
    end

    context 'when assigning an agent' do
      let(:service) { described_class.new(conversation: conversation, agent: agent) }

      it 'assigns the agent to the conversation' do
        service.call
        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when team has auto_assign enabled and no agent is provided' do
      let(:team) { create(:team, account: account, auto_assign: true) }
      let(:service) { described_class.new(conversation: conversation, team: team) }

      before do
        allow(AssignmentPolicies::Dispatcher).to receive(:call)
      end

      it 'calls the dispatcher' do
        service.call
        expect(AssignmentPolicies::Dispatcher).to have_received(:call).with(conversation: conversation)
      end
    end

    context 'when validation fails' do
      it 'raises error if team belongs to different account' do
        other_account = create(:account)
        other_team = create(:team, account: other_account)
        service = described_class.new(conversation: conversation, team: other_team)

        expect { service.call }.to raise_error(StandardError, /Team does not belong to the same account/)
      end

      it 'raises error if team is inactive' do
        # We need to skip this test if `active?` is not defined or we need to stub it
        # Actually `active?` might refer to a status column or method
        # If there's a status enum, let's mock it
        allow(team).to receive(:active?).and_return(false)
        service = described_class.new(conversation: conversation, team: team)

        expect { service.call }.to raise_error(ActiveRecord::RecordNotSaved, /Cannot assign conversation to an inactive team/)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe AssignmentPolicies::Engines::BaseEngine do
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox', inbox_users: double(pluck: [1, 2, 3])) }
  let(:team) { double('Team', team_users: team_users_scope) }
  let(:team_lead) { double('User', id: 2) }
  let(:lead_scope) { double('LeadScope') }
  let(:team_users_scope) { double('TeamUsersScope', pluck: [1, 2], lead: lead_scope) }
  
  let(:conversation) { double('Conversation', account: account, inbox: inbox, team: team) }
  let(:policy) { double('AssignmentPolicy', notify_team_leads?: false) }
  let(:service) { described_class.new(conversation: conversation, policy: policy) }

  describe '#call' do
    before do
      allow(lead_scope).to receive(:find_each).and_yield(double(user: team_lead))

      stub_const('Utilities::ActivityHelpers', double('ActivityHelpers'))
      allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(1).and_return(["1", "2"])

      stub_const('AssignmentPolicies::CapacityChecker', double('CapacityChecker'))
      allow(AssignmentPolicies::CapacityChecker).to receive(:call).with(agent_ids: ["1", "2"], policy: policy).and_return(["1"])
    end

    it 'raises NotImplementedError if select_agent is not overridden' do
      expect { service.call }.to raise_error(NotImplementedError)
    end

    context 'with a subclass that implements select_agent' do
      let(:agent) { double('User', id: 1) }
      let(:subclass) do
        Class.new(described_class) do
          def select_agent(ids)
            User.find_by(id: ids.first)
          end
        end
      end
      let(:service) { subclass.new(conversation: conversation, policy: policy) }

      before do
        stub_const('User', double('UserClass'))
        allow(User).to receive(:find_by).with(id: "1").and_return(agent)
      end

      it 'assigns agent and delegates notification to conversation.assign!' do
        expect(conversation).to receive(:assign!).with(agent)
        service.call
      end

      it 'notifies team leads if policy.notify_team_leads? is true' do
        allow(policy).to receive(:notify_team_leads?).and_return(true)
        expect(conversation).to receive(:assign!).with(agent)

        stub_const('Notification', double('NotificationClass'))
        expect(Notification).to receive(:create).with(
          account: account,
          user: team_lead,
          resource: conversation,
          event: :team_assigned
        )

        service.call
      end

      it 'leaves conversation unassigned when no agents are active in Redis' do
        allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(1).and_return([])
        expect(conversation).not_to receive(:assign!)

        expect(service.call).to be_nil
      end

      it 'leaves conversation unassigned when all online agents have reached max capacity' do
        allow(AssignmentPolicies::CapacityChecker).to receive(:call).with(agent_ids: ["1", "2"], policy: policy).and_return([])
        expect(conversation).not_to receive(:assign!)

        expect(service.call).to be_nil
      end
    end
  end
end

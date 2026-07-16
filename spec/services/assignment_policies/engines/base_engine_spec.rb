require 'rails_helper'

RSpec.describe AssignmentPolicies::Engines::BaseEngine do
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox', inbox_users: double(pluck: [1, 2, 3])) }
  let(:team) { double('Team', team_users: team_users_scope) }
  let(:team_users_scope) { double(pluck: [1, 2], lead: double(find_each: [])) }
  
  let(:conversation) { double('Conversation', account: account, inbox: inbox, team: team) }
  let(:policy) { double('AssignmentPolicy', notify_on_assignment?: true, notify_team_leads?: false) }
  let(:service) { described_class.new(conversation: conversation, policy: policy) }

  describe '#call' do
    before do
      stub_const('Utilities::ActivityHelpers', double('ActivityHelpers'))
      allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(1).and_return(["1", "2"])
      
      stub_const('AccountUser', double('AccountUser'))
      account_user_scope = double('AccountUserScope', pluck: ["1"])
      allow(AccountUser).to receive(:where).with(
        account: account,
        user_id: ["1", "2"],
        availability: :online
      ).and_return(account_user_scope)

      stub_const('AssignmentPolicies::CapacityChecker', double('CapacityChecker'))
      allow(AssignmentPolicies::CapacityChecker).to receive(:call).with(agent_ids: ["1"], policy: policy).and_return(["1"])
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

      it 'assigns agent and creates notification' do
        expect(conversation).to receive(:assign!).with(agent)
        
        stub_const('Notification', double('NotificationClass'))
        expect(Notification).to receive(:create).with(
          account: account,
          user: agent,
          resource: conversation,
          event: :conversation_assigned
        )

        service.call
      end
    end
  end
end

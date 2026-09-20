require 'rails_helper'

RSpec.describe Conversations::RoundRobinAssignment do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, auto_assign: true) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    let(:service) { described_class.new(conversation: conversation) }

    before do
      # Make users active in redis heartbeat
      allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(account.id).and_return([user1.id.to_s, user2.id.to_s])
      
      # Ensure inbox membership
      create(:inbox_user, inbox: inbox, user: user1)
      create(:inbox_user, inbox: inbox, user: user2)
      
      # Ensure account users are online
      create(:account_user, account: account, user: user1, availability: :online)
      create(:account_user, account: account, user: user2, availability: :online)
      
      # Reset redis round robin key
      allow(RedisUtilities::Helpers).to receive(:get).and_return(nil)
      allow(RedisUtilities::Helpers).to receive(:set)
    end

    context 'when auto_assign is false' do
      before { inbox.update(flags: 0) } # disable auto_assign flag 2

      it 'does nothing' do
        expect { service.call }.not_to change(Notification, :count)
        expect(conversation.reload.assignee_id).to be_nil
      end
    end

    context 'when auto_assign is true' do
      it 'assigns the conversation to an eligible agent' do
        expect { service.call }.to change(Notification, :count).by_at_least(1)
        
        expect(conversation.reload.assignee_id).to be_in([user1.id, user2.id])
      end

      it 'updates redis round robin key' do
        expect(RedisUtilities::Helpers).to receive(:set).with(instance_of(String), instance_of(String))
        service.call
      end
    end

    context 'when team is assigned' do
      let(:team) { create(:team, account: account, auto_assign: true) }
      
      before do
        conversation.update(team: team)
        create(:team_user, team: team, user: user1)
        # user2 is not in team
      end

      it 'only assigns to team members' do
        service.call
        expect(conversation.reload.assignee_id).to eq(user1.id)
      end
    end

    context 'when inbox has teams assigned but no direct users' do
      let(:team) { create(:team, account: account) }

      before do
        inbox.inbox_users.destroy_all
        create(:inbox_team, inbox: inbox, team: team)
        create(:team_user, team: team, user: user1)
      end

      it 'assigns the conversation to an agent from the inbox team' do
        service.call
        expect(conversation.reload.assignee_id).to eq(user1.id)
      end
    end
  end
end

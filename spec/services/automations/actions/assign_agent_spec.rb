require 'rails_helper'

RSpec.describe Automations::Actions::AssignAgent do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent) { create(:user) }

  before do
    create(:account_user, account: account, user: agent)
  end

  describe '#call' do
    context 'when agent is not found' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { agent_id: 999999 }) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when agent is found' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { agent_id: agent.id }) }

      it 'assigns the agent to the conversation' do
        expect(conversation).to receive(:assign!).with(agent)
        service.call
      end
    end
  end
end

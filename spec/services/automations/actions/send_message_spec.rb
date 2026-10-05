require 'rails_helper'

RSpec.describe Automations::Actions::SendMessage do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    allow(Messages::DeliveryWorker).to receive(:perform_async)
  end

  describe '#call' do
    context 'when content is missing' do
      let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

      it 'raises an error' do
        expect { service.call }.to raise_error('content is required')
      end
    end

    context 'with a global message and no actor (automation run)' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { content: 'Automated message' }) }

      it 'creates a global message sent by the account and enqueues delivery' do
        expect { service.call }.to change { conversation.messages.count }.by(1)

        message = conversation.messages.last
        expect(message.content).to eq('Automated message')
        expect(message.visibility).to eq('global')
        expect(message.content_type).to eq('text')
        expect(message.sender).to eq(account)
        expect(Messages::DeliveryWorker).to have_received(:perform_async).with(account.id, message.id)
      end
    end

    context 'with a private (personal) message' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { content: 'Private', visibility: 'personal' }) }

      it 'creates a personal message and does not deliver it to the customer channel' do
        service.call

        expect(conversation.messages.last.visibility).to eq('personal')
        expect(Messages::DeliveryWorker).not_to have_received(:perform_async)
      end
    end

    context 'with an actor (manual macro run)' do
      let(:agent) { create(:user, first_name: 'Sara') }
      let(:service) do
        described_class.new(resource: conversation, account: account, actor: agent, params: { content: 'Hi, I am {{ agent.first_name }}' })
      end

      it 'sends the message as the agent and renders variables' do
        service.call

        message = conversation.messages.last
        expect(message.sender).to eq(agent)
        expect(message.content).to include('Hi, I am Sara')
      end
    end
  end
end

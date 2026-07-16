require 'rails_helper'

RSpec.describe Automations::Actions::SendMessage do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#call' do
    context 'when content is missing' do
      let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

      it 'raises an error' do
        expect { service.call }.to raise_error('content is required')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { content: 'Automated message', visibility: 'personal' }) }

      before do
        stub_const('Messages::DeliveryWorker', double('DeliveryWorker', perform_async: true))
      end

      it 'creates a message and enqueues delivery' do
        expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, anything)
        expect { service.call }.to change { conversation.messages.count }.by(1)

        message = conversation.messages.last
        expect(message.content).to eq('Automated message')
        expect(message.visibility).to eq('personal')
        expect(message.content_type).to eq('text')
        expect(message.sender).to eq(account)
      end

      it 'enqueues delivery worker' do
        expect(Messages::DeliveryWorker).to receive(:perform_async)
        service.call
      end
    end

    context 'with default visibility' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { content: 'Automated message' }) }
      
      it 'uses global visibility by default' do
        service.call
        expect(conversation.messages.last.visibility).to eq('global')
      end
    end
  end
end

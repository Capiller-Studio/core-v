require 'rails_helper'

RSpec.describe Automations::Actions::AddNote do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user) }
  
  before do
    create(:account_user, account: account, user: user, owner: true)
  end

  describe '#call' do
    context 'with invalid resource' do
      let(:service) { described_class.new(resource: double('Customer'), account: account, params: { content: 'hello' }) }

      it 'raises an error' do
        expect { service.call }.to raise_error(/Resource must be a Conversation/)
      end
    end

    context 'when content is blank' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { content: '' }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('content is required')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { content: 'Internal note text' }) }

      it 'creates a personal activity message on the conversation' do
        expect { service.call }.to change { conversation.messages.count }.by(1)
        
        message = conversation.messages.last
        expect(message.content).to eq('Internal note text')
        expect(message.visibility).to eq('personal')
        expect(message.content_type).to eq('activity')
        expect(message.sender).to eq(account)
        expect(message.inbox).to eq(inbox)
        expect(message.source).to eq(conversation.source)
      end
    end
  end
end

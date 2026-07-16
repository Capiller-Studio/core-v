require 'rails_helper'

RSpec.describe Automations::Actions::AddLabel do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }

  describe '#call' do
    context 'with invalid resource' do
      let(:service) { described_class.new(resource: double('Customer'), account: account, params: { label_ids: [label1.id] }) }

      it 'raises an error' do
        expect { service.call }.to raise_error(/Resource must be a Conversation/)
      end
    end

    context 'when label_ids is blank' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { label_ids: [] }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('label_ids is required')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { label_ids: [label1.id, label2.id] }) }

      it 'adds the labels to the conversation' do
        expect { service.call }.to change { conversation.labels.count }.by(2)
        expect(conversation.labels).to include(label1, label2)
      end

      it 'does not add duplicate labels' do
        conversation.labels << label1
        expect { service.call }.to change { conversation.labels.count }.by(1)
        expect(conversation.labels).to include(label1, label2)
      end
    end
  end
end

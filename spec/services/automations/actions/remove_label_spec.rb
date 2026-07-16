require 'rails_helper'

RSpec.describe Automations::Actions::RemoveLabel do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }

  before do
    conversation.labels << label1
    conversation.labels << label2
  end

  describe '#call' do
    context 'when label_ids is blank' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { label_ids: [] }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('label_ids is required')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { label_ids: [label1.id] }) }

      it 'removes the specified labels from the conversation' do
        expect { service.call }.to change { conversation.labels.count }.by(-1)
        expect(conversation.labels).not_to include(label1)
        expect(conversation.labels).to include(label2)
      end
    end
  end
end

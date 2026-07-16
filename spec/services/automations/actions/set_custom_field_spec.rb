require 'rails_helper'

RSpec.describe Automations::Actions::SetCustomField do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, data: { 'existing_key' => 'old_value' }) }

  describe '#call' do
    context 'when key is missing' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { value: 'new_value' }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('key is required')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { key: 'new_key', value: 'new_val' }) }

      it 'updates the data jsonb column' do
        service.call
        expect(conversation.reload.data['existing_key']).to eq('old_value')
        expect(conversation.data['new_key']).to eq('new_val')
      end
    end
  end
end

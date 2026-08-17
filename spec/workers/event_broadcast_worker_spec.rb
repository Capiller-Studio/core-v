# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventBroadcastWorker, type: :worker do
  let(:account) { create(:account) }
  let(:payload) { { id: 1, content: 'Hello' } }
  let(:data_json) { payload.to_json }
  let(:event) { 'message.created' }
  let(:connection_tokens) { ['token_123'] }

  describe '#perform' do
    it 'broadcasts to ActionCable when event and tokens are present' do
      expect(ActionCables::EventBroadcaster).to receive(:call).with(
        data: data_json,
        event: event,
        connection_tokens: connection_tokens
      )

      described_class.new.perform(data_json, event, connection_tokens)
    end

    it 'dispatches to Integrations and Automations when account_id is provided' do
      allow(ActionCables::EventBroadcaster).to receive(:call)
      expect(Integrations::EventDispatcher).to receive(:call).with(
        event_name: event,
        payload: payload.stringify_keys,
        account: account
      )
      expect(Automations::EventDispatcher).to receive(:call).with(
        event_name: event,
        payload: payload.stringify_keys,
        account: account
      )

      described_class.new.perform(data_json, event, connection_tokens, account.id)
    end

    it 'returns early if event is blank' do
      expect(ActionCables::EventBroadcaster).not_to receive(:call)
      described_class.new.perform(data_json, '', connection_tokens)
    end

    it 'returns early if connection_tokens is blank' do
      expect(ActionCables::EventBroadcaster).not_to receive(:call)
      described_class.new.perform(data_json, event, nil)
    end
  end
end

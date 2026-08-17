# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::Sms::SignalwireController', type: :request do
  let(:account) { create(:account) }
  let(:channel) do
    account.with_shard do
      create(:channel_short_message, :signalwire, account: account)
    end
  end
  let(:params_payload) do
    {
      'MessageSid' => 'SM12345',
      'From' => '+15551234567',
      'To' => '+15557654321',
      'Body' => 'Signalwire SMS body'
    }
  end
  let(:url) { "/webhooks/sms/signalwire/#{account.id}/#{channel.id}" }

  before do
    allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_return(true)
  end

  describe 'POST /webhooks/sms/signalwire/:account_id/:channel_id' do
    context 'with valid signature' do
      it 'stores incoming webhook and queues SignalwireEventListenWorker' do
        expect(Webhooks::SignalwireEventListenWorker).to receive(:perform_async).with(kind_of(String))

        expect {
          post url, params: params_payload, headers: { 'X-SignalWire-Signature' => 'valid_sig' }
        }.to change { Webhook::Incoming.count }.by(1)

        expect(response).to have_http_status(:ok)

        incoming = Webhook::Incoming.last
        expect(incoming.source).to eq('signalwire')
      end
    end

    context 'with invalid signature' do
      it 'returns 401 unauthorized' do
        allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_return(false)

        post url, params: params_payload, headers: { 'X-SignalWire-Signature' => 'invalid_sig' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when channel is missing' do
      it 'returns 404 not found' do
        post "/webhooks/sms/signalwire/#{account.id}/non_existent_id", params: params_payload
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::Sms::TwilioController', type: :request do
  let(:account) { create(:account) }
  let(:channel) do
    account.with_shard do
      create(:channel_short_message, :twilio, account: account)
    end
  end
  let(:params_payload) do
    {
      'MessageSid' => 'SM99999',
      'From' => '+15551234567',
      'To' => '+15557654321',
      'Body' => 'Twilio SMS body'
    }
  end
  let(:url) { "/webhooks/sms/twilio/#{account.id}/#{channel.id}" }

  before do
    allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_return(true)
  end

  describe 'POST /webhooks/sms/twilio/:account_id/:channel_id' do
    context 'with valid signature' do
      it 'stores incoming webhook and queues TwilioEventListenWorker' do
        expect(Webhooks::TwilioEventListenWorker).to receive(:perform_async).with(kind_of(String))

        expect {
          post url, params: params_payload, headers: { 'X-Twilio-Signature' => 'valid_sig' }
        }.to change { Webhook::Incoming.count }.by(1)

        expect(response).to have_http_status(:ok)

        incoming = Webhook::Incoming.last
        expect(incoming.source).to eq('twilio')
      end
    end

    context 'with invalid signature' do
      it 'returns 401 unauthorized' do
        allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_return(false)

        post url, params: params_payload, headers: { 'X-Twilio-Signature' => 'invalid_sig' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when channel is missing' do
      it 'returns 404 not found' do
        post "/webhooks/sms/twilio/#{account.id}/non_existent_id", params: params_payload
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

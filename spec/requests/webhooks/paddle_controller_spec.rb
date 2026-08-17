# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::PaddleController', type: :request do
  describe 'POST /webhooks/paddle' do
    let(:webhook_secret) { 'test_paddle_secret' }
    let(:payload) do
      {
        'event_id' => 'evt_123',
        'event_type' => 'transaction.completed',
        'data' => { 'id' => 'txn_123', 'status' => 'paid' }
      }
    end
    let(:raw_body) { payload.to_json }
    let(:ts) { Time.current.to_i.to_s }
    let(:h1) { OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, "#{ts}:#{raw_body}") }
    let(:signature) { "ts=#{ts};h1=#{h1}" }

    before do
      allow(Rails.application.credentials).to receive(:dig).and_call_original
      allow(Rails.application.credentials).to receive(:dig).with(:paddle, :webhook_secret).and_return(webhook_secret)
    end

    context 'with valid signature' do
      it 'stores incoming webhook and queues PaddleEventListenWorker' do
        expect(Webhooks::PaddleEventListenWorker).to receive(:perform_async).with(kind_of(String))

        expect {
          post '/webhooks/paddle',
               params: raw_body,
               headers: {
                 'CONTENT_TYPE' => 'application/json',
                 'Paddle-Signature' => signature
               }
        }.to change { Webhook::Incoming.count }.by(1)

        expect(response).to have_http_status(:ok)

        incoming = Webhook::Incoming.last
        expect(incoming.source).to eq('paddle')
      end
    end

    context 'with invalid signature' do
      it 'returns 401 unauthorized' do
        post '/webhooks/paddle',
             params: raw_body,
             headers: {
               'CONTENT_TYPE' => 'application/json',
               'Paddle-Signature' => "ts=#{ts};h1=invalid_hash"
             }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without signature header' do
      it 'returns 401 unauthorized' do
        post '/webhooks/paddle',
             params: raw_body,
             headers: { 'CONTENT_TYPE' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

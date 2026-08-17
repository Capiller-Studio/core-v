# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::InstagramController', type: :request do
  describe 'GET /webhooks/instagram' do
    let(:verify_token) { 'test_instagram_verify_token' }

    before do
      allow(Rails.application.credentials).to receive(:dig).and_call_original
      allow(Rails.application.credentials).to receive(:dig).with(:channels, :instagram, :verify_token).and_return(verify_token)
    end

    context 'with valid hub.verify_token' do
      it 'renders challenge with 200 OK' do
        get '/webhooks/instagram', params: {
          'hub.mode' => 'subscribe',
          'hub.verify_token' => verify_token,
          'hub.challenge' => 'challenge_code_12345'
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('challenge_code_12345')
      end
    end

    context 'with invalid hub.verify_token' do
      it 'returns 403 forbidden' do
        get '/webhooks/instagram', params: {
          'hub.mode' => 'subscribe',
          'hub.verify_token' => 'wrong_token',
          'hub.challenge' => 'challenge_code_12345'
        }

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include('wrong validation token')
      end
    end
  end

  describe 'POST /webhooks/instagram' do
    let(:payload) do
      {
        'object' => 'instagram',
        'entry' => [
          {
            'id' => 'ig_entry_123',
            'messaging' => [
              { 'sender' => { 'id' => 'cust_1' }, 'recipient' => { 'id' => 'ig_page_1' }, 'message' => { 'text' => 'Hi' } }
            ]
          }
        ]
      }
    end

    it 'stores incoming webhook and queues InstagramEventListenWorker' do
      expect(Webhooks::InstagramEventListenWorker).to receive(:perform_async).with(kind_of(String))

      expect {
        post '/webhooks/instagram', params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
      }.to change { Webhook::Incoming.count }.by(1)

      expect(response).to have_http_status(:ok)

      incoming = Webhook::Incoming.last
      expect(incoming.source).to eq('instagram')
    end
  end
end

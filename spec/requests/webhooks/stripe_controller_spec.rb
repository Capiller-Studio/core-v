# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::StripeController', type: :request do
  describe 'POST /webhooks/stripe' do
    let(:webhook_secret) { 'whsec_test_secret' }
    let(:event_data) do
      {
        'id' => 'evt_stripe_123',
        'type' => 'invoice.payment_succeeded',
        'data' => { 'object' => { 'id' => 'in_123', 'amount_paid' => 5000 } }
      }
    end
    let(:raw_body) { event_data.to_json }

    before do
      allow(Rails.application.credentials).to receive(:dig).and_call_original
      allow(Rails.application.credentials).to receive(:dig).with(Rails.env.to_sym, :stripe, :webhook_secret).and_return(webhook_secret)
    end

    context 'with valid signature' do
      it 'stores incoming webhook and queues StripeEventListenWorker' do
        stripe_event = double('Stripe::Event', to_h: event_data)
        allow(::Stripe::Webhook).to receive(:construct_event).and_return(stripe_event)
        expect(Webhooks::StripeEventListenWorker).to receive(:perform_async).with(kind_of(String))

        expect {
          post '/webhooks/stripe',
               params: raw_body,
               headers: {
                 'CONTENT_TYPE' => 'application/json',
                 'HTTP_STRIPE_SIGNATURE' => 't=123,v1=valid_sig'
               }
        }.to change { Webhook::Incoming.count }.by(1)

        expect(response).to have_http_status(:ok)

        incoming = Webhook::Incoming.last
        expect(incoming.source).to eq('stripe')
      end
    end

    context 'with invalid signature' do
      it 'returns 401 unauthorized on SignatureVerificationError' do
        allow(::Stripe::Webhook).to receive(:construct_event).and_raise(::Stripe::SignatureVerificationError.new('Bad signature', 'sig_header'))

        post '/webhooks/stripe',
             params: raw_body,
             headers: {
               'CONTENT_TYPE' => 'application/json',
               'HTTP_STRIPE_SIGNATURE' => 'invalid_sig'
             }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with malformed payload' do
      it 'returns 400 bad request on JSON::ParserError' do
        allow(::Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError.new('Invalid JSON'))

        post '/webhooks/stripe',
             params: 'invalid json',
             headers: {
               'CONTENT_TYPE' => 'application/json',
               'HTTP_STRIPE_SIGNATURE' => 'valid_sig'
             }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end

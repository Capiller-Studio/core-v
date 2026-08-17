# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::Sms::AwsSnsController', type: :request do
  let(:account) { create(:account) }
  let(:channel) do
    account.with_shard do
      create(:channel_short_message, :aws_sns, account: account)
    end
  end
  let(:payload) do
    {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_123',
      'Message' => 'Hello from SMS'
    }
  end

  describe 'POST /webhooks/sms/aws_sns/:account_id/:channel_id' do
    let(:url) { "/webhooks/sms/aws_sns/#{account.id}/#{channel.id}" }

    before do
      allow_any_instance_of(Aws::SNS::MessageVerifier).to receive(:authentic?).and_return(true)
    end

    context 'when channel exists and signature is authentic' do
      it 'stores incoming webhook and queues AwsSnsEventListenWorker' do
        expect(Webhooks::AwsSnsEventListenWorker).to receive(:perform_async).with(kind_of(String))

        expect {
          post url, params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
        }.to change { Webhook::Incoming.count }.by(1)

        expect(response).to have_http_status(:ok)

        incoming = Webhook::Incoming.last
        expect(incoming.source).to eq('aws_sns')
      end
    end

    context 'when signature verification fails' do
      it 'returns 401 unauthorized' do
        allow_any_instance_of(Aws::SNS::MessageVerifier).to receive(:authentic?).and_return(false)

        post url, params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when channel does not exist' do
      it 'returns 404 not found' do
        post "/webhooks/sms/aws_sns/#{account.id}/non_existent_id",
             params: payload.to_json,
             headers: { 'CONTENT_TYPE' => 'application/json' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

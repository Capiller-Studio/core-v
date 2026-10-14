# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Channel::Custom Comprehensive Edge Cases Suite', type: :service do
  let(:account) { create(:account, shard_key: 'de') }

  let(:custom_channel) do
    account.with_shard do
      channel = create(:channel_custom, account: account, name: 'Core ERP Integration')
      create(:inbox, channel: channel, account: account, primary_inbox: true)
      channel
    end
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.partner-service.com').and_return(['93.184.216.34'])
  end

  describe 'Channel::Custom Model Edge Cases & Cryptographic Defaults' do
    it 'auto-generates unique identifier, encrypted webhook_secret, and encrypted hmac_token' do
      channel = account.with_shard do
        create(:channel_custom,
          account: account,
          name: 'Partner Webhook Hub',
          webhook_url: 'https://api.partner-service.com/webhook'
        )
      end

      expect(channel.identifier).to start_with('partner-webhook-hub')
      expect(channel.webhook_secret).to be_present
      expect(channel.hmac_token).to be_present
      expect(channel.webhook_endpoint).to include("/webhooks/custom/#{account.id}/#{channel.id}")
    end

    it 'resolves identifier collisions gracefully by appending random hex' do
      account.with_shard do
        ch1 = create(:channel_custom, account: account, name: 'Billing Hook')
        ch2 = create(:channel_custom, account: account, name: 'Billing Hook')

        expect(ch1.identifier).to eq('billing-hook')
        expect(ch2.identifier).to match(/\Abilling-hook-[a-f0-9]{8}\z/)
      end
    end

    it 'validates webhook_url against SSRF attacks rejecting internal IP targets' do
      channel = account.with_shard do
        build(:channel_custom,
          account: account,
          name: 'SSRF Attack Vector',
          webhook_url: 'http://169.254.169.254/latest/meta-data/'
        )
      end

      expect(channel).not_to be_valid
      expect(channel.errors[:webhook_url]).to be_present
    end
  end

  describe 'Webhooks::CustomEventListenWorker Edge Cases' do
    let(:worker) { Webhooks::CustomEventListenWorker.new }

    before do
      allow_any_instance_of(Webhook::Incoming).to receive(:route_params).and_return(
        { account_id: account.id, channel_id: custom_channel.id }
      )
    end

    it 'returns nil gracefully when Webhook::Incoming record cannot be found' do
      expect {
        worker.perform('non-existent-webhook-id')
      }.not_to raise_error
    end

    it 'skips payload processing if channel is disconnected' do
      account.with_shard { custom_channel.disconnected! }

      webhook = create(:webhook_incoming,
        source: 'custom',
        request_url: "https://deskbolic.app/webhooks/custom/#{account.id}/#{custom_channel.id}",
        payload: {
          event: 'message.created',
          message: { content: 'This should be skipped' }
        }
      )

      expect(Channels::Custom::ConversationCreator).not_to receive(:new)

      worker.perform(webhook.id)
      expect(webhook.reload.status).to eq('pending')
    end

    it 'marks webhook processed and warns without error for unsupported events' do
      webhook = create(:webhook_incoming,
        source: 'custom',
        request_url: "https://deskbolic.app/webhooks/custom/#{account.id}/#{custom_channel.id}",
        payload: {
          event: 'typing.started',
          user_id: 'usr_99'
        }
      )

      expect(Rails.logger).to receive(:warn).with(/unsupported event type 'typing.started'/)

      worker.perform(webhook.id)
      expect(webhook.reload.status).to eq('processed')
    end

    it 'records error trace and re-raises exception for Sidekiq retry on processing failure' do
      webhook = create(:webhook_incoming,
        source: 'custom',
        request_url: "https://deskbolic.app/webhooks/custom/#{account.id}/#{custom_channel.id}",
        payload: {
          event: 'message.created',
          message: { content: 'Will fail' }
        }
      )

      allow_any_instance_of(Channels::Custom::ConversationCreator).to receive(:call).and_raise(
        StandardError.new('Critical shard connection failure')
      )

      expect {
        worker.perform(webhook.id)
      }.to raise_error(StandardError, 'Critical shard connection failure')

      webhook.reload
      expect(webhook.status).to eq('failed')
      expect(webhook.error_message).to include('Critical shard connection failure')
    end
  end

  describe 'Channels::Custom::ConversationCreator End-to-End Pipeline' do
    it 'creates customer, conversation with external_id, member, and incoming message' do
      creator = Channels::Custom::ConversationCreator.new(
        custom_channel: custom_channel,
        customer_params: {
          email: 'custom.shopper@store.example.com',
          name: 'Jane Customer',
          external_id: 'CUST-EXT-7722'
        },
        content: 'I need an update on my order #7722',
        conversation_data: {
          title: 'Order Tracking #7722',
          priority: 'high',
          data: { 'order_id' => '7722' }
        },
        external_id: 'CONV-EXT-7722'
      )

      conversation = creator.call

      expect(conversation).to be_present
      expect(conversation.external_id).to eq('CONV-EXT-7722')
      expect(conversation.title).to eq('Order Tracking #7722')
      expect(conversation.high?).to be(true)
      expect(conversation.data['order_id']).to eq('7722')
      expect(conversation.custom_source?).to be(true)

      # Verify customer and members
      customer = conversation.customers.first
      expect(customer).to be_present
      expect(customer.email).to eq('custom.shopper@store.example.com')
      expect(customer.name).to eq('Jane Customer')
      expect(customer.external_id).to eq('CUST-EXT-7722')

      # Verify message
      expect(conversation.messages.count).to eq(1)
      message = conversation.messages.first
      expect(message.content).to eq('I need an update on my order #7722')
      expect(message.sender).to eq(customer)
      expect(message.custom_source?).to be(true)
    end

    it 'reuses existing conversation when external_id matches rather than duplicating' do
      # Pre-create conversation
      existing_conv = account.with_shard do
        account.conversations.create!(
          inbox: custom_channel.primary_inbox,
          source: :custom,
          external_id: 'EXISTING-TICKET-99',
          title: 'Existing Support Thread'
        )
      end

      creator = Channels::Custom::ConversationCreator.new(
        custom_channel: custom_channel,
        customer_params: { email: 'repeat.client@example.com', name: 'Repeat Client' },
        content: 'Follow-up message on ticket #99',
        external_id: 'EXISTING-TICKET-99'
      )

      conversation = creator.call
      expect(conversation.id).to eq(existing_conv.id)
      expect(conversation.messages.last.content).to eq('Follow-up message on ticket #99')
    end
  end

  describe 'Outbound Webhook Delivery on Custom Channel' do
    let(:outbound_delivery) do
      account.with_shard do
        create(:webhook_delivery,
          account: account,
          resource: custom_channel,
          event_name: 'message.sent',
          endpoint_url: 'https://api.partner-service.com/webhook',
          request_payload: { event: 'message.sent', content: 'Agent response' },
          status: :pending
        )
      end
    end

    it 'dispatches payload signed with custom_channel.hmac_token' do
      allow(Security::UrlValidator).to receive(:valid_url?).and_return(true)

      expect(HTTParty).to receive(:post).with(
        'https://api.partner-service.com/webhook',
        body: outbound_delivery.request_payload.to_json,
        headers: hash_including(
          'Signature' => a_string_matching(/\At=\d+,v1=[a-f0-9]{64}\z/)
        ),
        timeout: 10
      ).and_return(double('Response', success?: true, code: 200, body: '{"ok":true}'))

      Integrations::Webhooks::BroadcasterWorker.new.perform(account.id, outbound_delivery.id, 1)

      outbound_delivery.reload
      expect(outbound_delivery).to be_successful
    end
  end
end

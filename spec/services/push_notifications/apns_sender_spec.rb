# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PushNotifications::ApnsSender do
  let!(:account) { create(:account) }
  let(:ec_key) { OpenSSL::PKey::EC.generate('prime256v1') }
  let!(:channel) do
    account.with_shard do
      create(
        :channel_mobile_widget,
        account: account,
        apns_key: ec_key.to_pem,
        apns_key_id: 'KEYID12345',
        apns_team_id: 'TEAMID1234',
        ios_bundle_id: 'com.deskbolic.app',
        apns_environment: :production
      )
    end
  end
  let!(:inbox) { account.with_shard { create(:inbox, account: account, channel: channel) } }
  let!(:customer) { account.with_shard { create(:customer, account: account) } }
  let!(:customer_inbox) { account.with_shard { create(:customer_inbox, inbox: inbox, customer: customer) } }
  let!(:device) do
    account.with_shard do
      create(
        :customer_device,
        account: account,
        inbox: inbox,
        customer: customer,
        customer_inbox: customer_inbox,
        push_token: 'valid_apns_device_token_abc123',
        platform: :ios,
        push_provider: :apns,
        status: :active
      )
    end
  end

  let(:payload) do
    {
      title: 'Agent Smith',
      body: 'Your ticket has been updated',
      badge: 3,
      data: { conversation_id: 'conv_123', message_id: 'msg_456' }
    }
  end

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe '#call' do
    it 'returns false if APNs is not configured on the channel' do
      unconfigured_channel = create(:channel_mobile_widget, account: account)
      result = described_class.call(channel: unconfigured_channel, device: device, payload: payload)
      expect(result).to be false
    end

    it 'returns false if device push token is blank' do
      device.update_columns(push_token: '')
      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be false
    end

    it 'sends push notification via HTTP/2 and updates device last_push_at on 200 OK' do
      mock_response = double('Typhoeus::Response', code: 200, body: '')
      mock_request = double('Typhoeus::Request', run: mock_response)

      expect(Typhoeus::Request).to receive(:new).with(
        'https://api.push.apple.com/3/device/valid_apns_device_token_abc123',
        hash_including(
          method: :post,
          headers: hash_including(
            'apns-topic' => 'com.deskbolic.app',
            'apns-push-type' => 'alert',
            'apns-priority' => '10'
          ),
          http_version: :httpv2_0
        )
      ).and_return(mock_request)

      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be true
      expect(device.reload.last_push_at).to be_present
    end

    it 'uses sandbox host when apns_environment is sandbox' do
      channel.update!(apns_environment: :sandbox)
      mock_response = double('Typhoeus::Response', code: 200, body: '')
      mock_request = double('Typhoeus::Request', run: mock_response)

      expect(Typhoeus::Request).to receive(:new).with(
        'https://api.sandbox.push.apple.com/3/device/valid_apns_device_token_abc123',
        anything
      ).and_return(mock_request)

      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be true
    end

    it 'invalidates device token when APNs responds with 410 Unregistered' do
      mock_response = double('Typhoeus::Response', code: 410, body: '{"reason":"Unregistered"}')
      mock_request = double('Typhoeus::Request', run: mock_response)
      allow(Typhoeus::Request).to receive(:new).and_return(mock_request)

      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be false
      expect(device.reload.status).to eq('invalid_token')
      expect(device.data['last_error']).to include('410')
    end

    it 'invalidates device token when APNs responds with 400 BadDeviceToken' do
      mock_response = double('Typhoeus::Response', code: 400, body: '{"reason":"BadDeviceToken"}')
      mock_request = double('Typhoeus::Request', run: mock_response)
      allow(Typhoeus::Request).to receive(:new).and_return(mock_request)

      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be false
      expect(device.reload.status).to eq('invalid_token')
    end

    it 'handles network errors or exceptions gracefully without crashing' do
      allow(Typhoeus::Request).to receive(:new).and_raise(StandardError.new('Connection reset by peer'))

      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be false
    end
  end
end

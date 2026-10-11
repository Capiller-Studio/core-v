# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PushNotifications::FcmSender do
  let!(:account) { create(:account) }
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:service_account_hash) do
    {
      type: 'service_account',
      project_id: 'deskbolic-firebase-prod',
      private_key: rsa_key.to_pem,
      client_email: 'firebase-admin@deskbolic-firebase-prod.iam.gserviceaccount.com'
    }
  end

  let!(:channel) do
    account.with_shard do
      create(
        :channel_mobile_widget,
        account: account,
        android_package_name: 'com.deskbolic.app',
        fcm_service_account: service_account_hash.to_json
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
        push_token: 'fcm_registration_token_xyz987',
        platform: :android,
        push_provider: :fcm,
        status: :active
      )
    end
  end

  let(:payload) do
    {
      title: 'Support Agent',
      body: 'How can we help you?',
      data: { conversation_id: 'conv_888', message_id: 'msg_999' }
    }
  end

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe '#call' do
    it 'returns false if FCM is not configured on the channel' do
      unconfigured_channel = create(:channel_mobile_widget, account: account)
      result = described_class.call(channel: unconfigured_channel, device: device, payload: payload)
      expect(result).to be false
    end

    it 'returns false if device push token is blank' do
      device.update_columns(push_token: '')
      result = described_class.call(channel: channel, device: device, payload: payload)
      expect(result).to be false
    end

    context 'with valid OAuth2 token exchange' do
      let(:oauth_response) do
        instance_double(
          Net::HTTPSuccess,
          is_a?: true,
          body: { access_token: 'ya29.mock_oauth_token', expires_in: 3600 }.to_json
        )
      end

      before do
        allow(Net::HTTP).to receive(:post_form).and_return(oauth_response)
      end

      it 'sends push notification via FCM v1 and updates device last_push_at on 200 OK' do
        fcm_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).with('fcm.googleapis.com', 443).and_return(fcm_http)
        allow(fcm_http).to receive(:use_ssl=)
        allow(fcm_http).to receive(:open_timeout=)
        allow(fcm_http).to receive(:read_timeout=)

        fcm_success_response = instance_double(Net::HTTPSuccess, code: '200', body: '{"name":"projects/deskbolic-firebase-prod/messages/123"}')
        expect(fcm_http).to receive(:request).and_return(fcm_success_response)

        result = described_class.call(channel: channel, device: device, payload: payload)
        expect(result).to be true
        expect(device.reload.last_push_at).to be_present
      end

      it 'invalidates dead device token on 404 UNREGISTERED response' do
        fcm_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).with('fcm.googleapis.com', 443).and_return(fcm_http)
        allow(fcm_http).to receive(:use_ssl=)
        allow(fcm_http).to receive(:open_timeout=)
        allow(fcm_http).to receive(:read_timeout=)

        fcm_error_response = instance_double(Net::HTTPNotFound, code: '404', body: '{"error":{"details":[{"@type":"type.googleapis.com/google.firebase.fcm.v1.FcmError","errorCode":"UNREGISTERED"}]}}')
        expect(fcm_http).to receive(:request).and_return(fcm_error_response)

        result = described_class.call(channel: channel, device: device, payload: payload)
        expect(result).to be false
        expect(device.reload.status).to eq('invalid_token')
        expect(device.data['last_error']).to include('404')
      end

      it 'returns false on unexpected server errors' do
        fcm_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).with('fcm.googleapis.com', 443).and_return(fcm_http)
        allow(fcm_http).to receive(:use_ssl=)
        allow(fcm_http).to receive(:open_timeout=)
        allow(fcm_http).to receive(:read_timeout=)

        fcm_server_error = instance_double(Net::HTTPInternalServerError, code: '500', body: 'Internal Error')
        expect(fcm_http).to receive(:request).and_return(fcm_server_error)

        result = described_class.call(channel: channel, device: device, payload: payload)
        expect(result).to be false
        expect(device.reload.status).to eq('active')
      end
    end

    context 'when OAuth2 token exchange fails' do
      it 'returns false and logs error' do
        oauth_error_response = instance_double(Net::HTTPUnauthorized, is_a?: false, code: '401', body: '{"error":"invalid_client"}')
        allow(Net::HTTP).to receive(:post_form).and_return(oauth_error_response)

        result = described_class.call(channel: channel, device: device, payload: payload)
        expect(result).to be false
      end
    end

    context 'when network exception occurs' do
      it 'handles exception safely without crashing' do
        allow(Net::HTTP).to receive(:post_form).and_raise(SocketError.new('Failed to open TCP connection'))

        result = described_class.call(channel: channel, device: device, payload: payload)
        expect(result).to be false
      end
    end
  end
end

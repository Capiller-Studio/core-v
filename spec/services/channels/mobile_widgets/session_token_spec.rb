# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::MobileWidgets::SessionToken do
  let(:account_id) { SecureRandom.uuid }
  let(:channel_id) { SecureRandom.uuid }
  let(:inbox_id) { SecureRandom.uuid }
  let(:customer_id) { SecureRandom.uuid }
  let(:secret) { 'my_secure_channel_secret_key_998877' }

  let(:channel) do
    double('Channel::MobileWidget', id: channel_id, account_id: account_id, secret: secret)
  end

  let(:customer) { double('Customer', id: customer_id) }
  let(:customer_inbox) do
    double('CustomerInbox', inbox_id: inbox_id, connection_token: 'ct_token_12345')
  end

  describe '.encode and .decode' do
    it 'encodes and successfully decodes a valid session token' do
      token = described_class.encode(
        customer: customer,
        customer_inbox: customer_inbox,
        channel: channel
      )

      expect(token).to be_present

      decoded = described_class.decode(token, channel: channel)
      expect(decoded).to be_present
      expect(decoded[:customer_id]).to eq(customer_id)
      expect(decoded[:channel_id]).to eq(channel_id)
      expect(decoded[:account_id]).to eq(account_id)
      expect(decoded[:inbox_id]).to eq(inbox_id)
      expect(decoded[:purpose]).to eq('mobile_widget_customer')
    end

    it 'returns nil when token has expired' do
      token = described_class.encode(
        customer: customer,
        customer_inbox: customer_inbox,
        channel: channel,
        expiry: -1.minute
      )

      decoded = described_class.decode(token, channel: channel)
      expect(decoded).to be_nil
    end

    it 'returns nil when decoded with a different channel secret' do
      token = described_class.encode(
        customer: customer,
        customer_inbox: customer_inbox,
        channel: channel
      )

      other_channel = double('Channel::MobileWidget', id: channel_id, account_id: account_id, secret: 'wrong_secret')
      decoded = described_class.decode(token, channel: other_channel)
      expect(decoded).to be_nil
    end

    it 'returns nil when token purpose is altered' do
      payload = {
        purpose: 'wrong_purpose',
        account_id: account_id,
        channel_id: channel_id,
        customer_id: customer_id,
        exp: 1.day.from_now.to_i
      }
      token = JWT.encode(payload, secret, 'HS256')

      decoded = described_class.decode(token, channel: channel)
      expect(decoded).to be_nil
    end

    it 'returns nil when channel_id in token does not match channel' do
      token = described_class.encode(
        customer: customer,
        customer_inbox: customer_inbox,
        channel: channel
      )

      different_channel = double('Channel::MobileWidget', id: SecureRandom.uuid, account_id: account_id, secret: secret)
      decoded = described_class.decode(token, channel: different_channel)
      expect(decoded).to be_nil
    end

    it 'returns nil for blank or malformed token strings' do
      expect(described_class.decode(nil, channel: channel)).to be_nil
      expect(described_class.decode('', channel: channel)).to be_nil
      expect(described_class.decode('malformed.junk.token', channel: channel)).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::MobileWidgets::IdentityVerifier do
  let(:secret) { 'test_channel_secret_key_1234567890' }
  let(:channel) { double('Channel::MobileWidget', secret: secret, secure_identity_enforced?: false) }

  describe '#call' do
    context 'with JWT verification (HS256)' do
      let(:payload) do
        {
          sub: 'usr_sub_100',
          email: 'sub@example.com',
          name: 'Sub User',
          phone_number: '+15551234567',
          avatar_url: 'https://example.com/avatar.png',
          custom_attributes: { plan: 'pro', role: 'admin' },
          exp: (Time.current + 1.hour).to_i
        }
      end

      it 'verifies valid JWT and extracts standard sub claim' do
        token = JWT.encode(payload, secret, 'HS256')
        result = described_class.call(channel: channel, params: { jwt: token })

        expect(result).to be_present
        expect(result[:external_id]).to eq('usr_sub_100')
        expect(result[:email]).to eq('sub@example.com')
        expect(result[:name]).to eq('Sub User')
        expect(result[:phone_number]).to eq('+15551234567')
        expect(result[:avatar_url]).to eq('https://example.com/avatar.png')
        expect(result[:custom_attributes]).to eq({ 'plan' => 'pro', 'role' => 'admin' })
      end

      it 'supports alternative user_id claim in JWT payload' do
        custom_payload = payload.except(:sub).merge(user_id: 'usr_alt_200')
        token = JWT.encode(custom_payload, secret, 'HS256')
        result = described_class.call(channel: channel, params: { jwt: token })

        expect(result[:external_id]).to eq('usr_alt_200')
      end

      it 'supports alternative external_id claim in JWT payload' do
        custom_payload = payload.except(:sub).merge(external_id: 'usr_ext_300')
        token = JWT.encode(custom_payload, secret, 'HS256')
        result = described_class.call(channel: channel, params: { jwt: token })

        expect(result[:external_id]).to eq('usr_ext_300')
      end

      it 'returns nil when JWT signature has expired' do
        expired_payload = payload.merge(exp: (Time.current - 10.seconds).to_i)
        token = JWT.encode(expired_payload, secret, 'HS256')
        result = described_class.call(channel: channel, params: { jwt: token })

        expect(result).to be_nil
      end

      it 'returns nil when signed with a different secret' do
        token = JWT.encode(payload, 'wrong_secret', 'HS256')
        result = described_class.call(channel: channel, params: { jwt: token })

        expect(result).to be_nil
      end

      it 'returns nil when JWT is completely malformed' do
        result = described_class.call(channel: channel, params: { jwt: 'not.a.valid.jwt' })
        expect(result).to be_nil
      end
    end

    context 'with HMAC-SHA256 signature verification' do
      let(:identifier) { 'cust_hmac_42' }
      let(:signature) { OpenSSL::HMAC.hexdigest('sha256', secret, identifier) }

      it 'verifies valid HMAC signature against identifier' do
        result = described_class.call(
          channel: channel,
          params: {
            identifier: identifier,
            signature: signature,
            email: 'hmac@example.com',
            name: 'HMAC Customer',
            phone_number: '+18889990000',
            custom_attributes: { vip: true }
          }
        )

        expect(result).to be_present
        expect(result[:external_id]).to eq(identifier)
        expect(result[:email]).to eq('hmac@example.com')
        expect(result[:name]).to eq('HMAC Customer')
        expect(result[:phone_number]).to eq('+18889990000')
        expect(result[:custom_attributes]).to eq({ 'vip' => true })
      end

      it 'returns nil when HMAC signature does not match' do
        result = described_class.call(
          channel: channel,
          params: {
            identifier: identifier,
            signature: 'invalid_hmac_signature',
            email: 'hmac@example.com'
          }
        )

        expect(result).to be_nil
      end

      it 'returns nil when identifier is tampered' do
        result = described_class.call(
          channel: channel,
          params: {
            identifier: 'tampered_identifier',
            signature: signature
          }
        )

        expect(result).to be_nil
      end
    end

    context 'with guest / unverified parameters' do
      context 'when secure_identity_enforced is false' do
        before do
          allow(channel).to receive(:secure_identity_enforced?).and_return(false)
        end

        it 'allows unverified guest session' do
          result = described_class.call(
            channel: channel,
            params: {
              identifier: 'guest-123',
              name: 'Guest User',
              email: 'guest@example.com'
            }
          )

          expect(result).to be_present
          expect(result[:external_id]).to eq('guest-123')
          expect(result[:name]).to eq('Guest User')
          expect(result[:email]).to eq('guest@example.com')
        end
      end

      context 'when secure_identity_enforced is true' do
        before do
          allow(channel).to receive(:secure_identity_enforced?).and_return(true)
        end

        it 'rejects unverified guest sessions and returns nil' do
          result = described_class.call(
            channel: channel,
            params: {
              name: 'Unverified Guest',
              email: 'unverified@example.com'
            }
          )

          expect(result).to be_nil
        end
      end
    end
  end
end

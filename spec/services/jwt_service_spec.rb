require 'rails_helper'
require 'jwt'

RSpec.describe JwtService do
  include ActiveSupport::Testing::TimeHelpers
  
  let(:payload) { { user_id: 1, role: 'admin' } }
  let(:secret_key) { 'dummy_secret_key_for_testing' }

  before do
    allow(JwtService).to receive(:secret_key).and_return(secret_key)
  end

  describe '.encode' do
    it 'encodes a payload into a JWT token' do
      token = described_class.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').size).to eq(3) # Header, Payload, Signature
    end

    it 'adds standard claims (exp and iat) to the payload' do
      freeze_time do
        token = described_class.encode(payload)
        decoded = JWT.decode(token, secret_key, true, { algorithm: JwtService::ALGORITHM }).first
        
        expect(decoded['exp']).to eq(24.hours.from_now.to_i)
        expect(decoded['iat']).to eq(Time.current.to_i)
        expect(decoded['user_id']).to eq(1)
        expect(decoded['role']).to eq('admin')
      end
    end

    it 'allows overriding the default expiry' do
      freeze_time do
        token = described_class.encode(payload, expiry: 1.hour)
        decoded = described_class.decode(token)
        
        expect(decoded['exp']).to eq(1.hour.from_now.to_i)
      end
    end
  end

  describe '.decode' do
    context 'with a valid token' do
      let(:token) { described_class.encode(payload) }

      it 'decodes the token and returns the payload with indifferent access' do
        decoded = described_class.decode(token)
        
        expect(decoded).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(decoded[:user_id]).to eq(1)
        expect(decoded['role']).to eq('admin')
      end
    end

    context 'with an expired token' do
      it 'returns nil' do
        token = described_class.encode(payload, expiry: -1.minute)
        expect(described_class.decode(token)).to be_nil
      end
    end

    context 'with an invalid token' do
      it 'returns nil' do
        expect(described_class.decode('invalid.token.string')).to be_nil
      end
    end
  end
end

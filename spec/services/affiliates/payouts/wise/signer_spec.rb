require 'rails_helper'

RSpec.describe Affiliates::Payouts::Wise::Signer do
  let(:token) { 'my-token' }
  let(:service) { described_class.new(token) }

  describe '#call' do
    context 'when token is blank' do
      let(:token) { '' }
      it 'returns nil' do
        expect(service.call).to be_nil
      end
    end

    context 'when token is present' do
      let(:private_key) { OpenSSL::PKey::RSA.generate(2048) }
      let(:private_key_pem) { private_key.to_pem }

      before do
        allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :private_key).and_return(private_key_pem)
      end

      it 'returns a strict base64 encoded signature' do
        signature = service.call
        expect(signature).to be_a(String)
        expect(signature).not_to include("\n")
        
        # Verify signature
        public_key = private_key.public_key
        decoded_sig = Base64.strict_decode64(signature)
        expect(public_key.verify(OpenSSL::Digest.new('SHA256'), decoded_sig, token)).to be(true)
      end
    end

    context 'when private key is missing' do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :private_key).and_return(nil)
      end

      it 'raises an error' do
        expect { service.call }.to raise_error("Wise Private Key not configured in credentials")
      end
    end
  end
end

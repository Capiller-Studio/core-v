require 'rails_helper'

RSpec.describe Channels::WebWidgets::IdentityVerifier do
  let(:widget) { double('Channel::WebWidget', hmac_token: 'secret_token') }
  let(:identifier) { 'user@example.com' }
  
  let(:expected_signature) do
    OpenSSL::HMAC.hexdigest('sha256', 'secret_token', 'user@example.com')
  end
  
  let(:service) do
    described_class.new(
      widget: widget,
      identifier: identifier,
      signature: expected_signature
    )
  end

  describe '#call' do
    it 'returns true for a valid signature' do
      expect(service.call).to be(true)
    end

    context 'when signature is invalid' do
      let(:service) do
        described_class.new(
          widget: widget,
          identifier: identifier,
          signature: 'invalid_signature'
        )
      end

      it 'returns false' do
        expect(service.call).to be(false)
      end
    end

    context 'when signature is blank' do
      let(:service) do
        described_class.new(
          widget: widget,
          identifier: identifier,
          signature: ''
        )
      end

      it 'returns false' do
        expect(service.call).to be(false)
      end
    end

    context 'when identifier is different' do
      let(:service) do
        described_class.new(
          widget: widget,
          identifier: 'other@example.com',
          signature: expected_signature
        )
      end

      it 'returns false' do
        expect(service.call).to be(false)
      end
    end
  end
end

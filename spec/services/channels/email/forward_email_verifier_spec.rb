require 'rails_helper'

RSpec.describe Channels::Email::ForwardEmailVerifier do
  let(:email_channel) { double('Channel::Email', email: 'test@example.com', id: 1) }
  let(:service) { described_class.new(email_channel) }

  describe '#call' do
    let(:mailer_mock) { double('SystemMailer', deliver_later: true) }

    before do
      stub_const('SystemMailer', double('SystemMailer'))
      allow(SystemMailer).to receive(:forward_email_verification).with(email_channel).and_return(mailer_mock)
      
      allow(email_channel).to receive(:regenerate_forward_email_token)
      allow(email_channel).to receive(:forwarding_verified_at=)
      allow(email_channel).to receive(:save!)
    end

    it 'regenerates token, saves, and sends verification email' do
      expect(email_channel).to receive(:regenerate_forward_email_token)
      expect(email_channel).to receive(:forwarding_verified_at=).with(nil)
      expect(email_channel).to receive(:save!).with(validate: false)
      expect(mailer_mock).to receive(:deliver_later)

      expect(service.call).to be(true)
    end

    context 'when email is blank' do
      before do
        allow(email_channel).to receive(:email).and_return('')
      end

      it 'returns false early' do
        expect(email_channel).not_to receive(:regenerate_forward_email_token)
        expect(service.call).to be(false)
      end
    end

    context 'when an error occurs' do
      before do
        allow(email_channel).to receive(:save!).and_raise(StandardError.new('DB error'))
      end

      it 'logs the error and returns false' do
        expect(Rails.logger).to receive(:error).with(/ForwardEmailVerifier failed for Channel::Email#1: DB error/)
        expect(service.call).to be(false)
      end
    end
  end
end

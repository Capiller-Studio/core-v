require 'rails_helper'

RSpec.describe Channels::EmailChannelSearcher do
  describe '#call' do
    before do
      stub_const('Channel::Email', double('ChannelEmailClass'))
    end

    it 'searches for emails directly' do
      service = described_class.new(emails: ['test@example.com'])
      expect(Channel::Email).to receive(:where).with("email IN (:emails) OR forward_email IN (:emails)", emails: ['test@example.com']).and_return(['channel1'])
      
      expect(service.call).to eq(['channel1'])
    end

    it 'parses emails from mail object' do
      mail = double('Mail', to: ['to@example.com'], bcc: ['bcc@example.com'], cc: [])
      allow(mail).to receive(:[]).with("X-Original-To").and_return(double(value: 'orig@example.com'))
      service = described_class.new(mail: mail)
      
      expected_emails = ['to@example.com', 'bcc@example.com', 'orig@example.com']
      expect(Channel::Email).to receive(:where).with("email IN (:emails) OR forward_email IN (:emails)", emails: expected_emails).and_return(['channel2'])
      
      expect(service.call).to eq(['channel2'])
    end

    it 'returns nil if no emails' do
      service = described_class.new(emails: [])
      expect(Channel::Email).not_to receive(:where)
      expect(service.call).to be_nil
    end
  end
end

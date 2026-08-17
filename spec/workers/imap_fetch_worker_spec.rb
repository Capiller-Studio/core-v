# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImapFetchWorker, type: :worker do
  let(:account) { create(:account) }
  let(:email_channel) do
    create(:channel_email,
      account: account,
      status: :active,
      imap_enabled: true,
      imap_configurations: {
        'address' => 'imap.example.com',
        'port' => 993,
        'username' => 'support@example.com',
        'password' => 'secret_password'
      }
    )
  end

  describe '#perform' do
    it 'calls Channels::Email::ImapFetcher for active IMAP-enabled email channels' do
      expect(Channels::Email::ImapFetcher).to receive(:call).with(email_channel: email_channel)
      allow(Account).to receive(:pluck).with(:shard_key).and_return([ShardRecord.current_shard.to_s])
      allow(Channel::Email).to receive_message_chain(:imap_enabled, :where, :find_each).and_yield(email_channel)

      described_class.new.perform
    end

    it 'rescues errors per channel and logs error' do
      allow(Account).to receive(:pluck).with(:shard_key).and_return([ShardRecord.current_shard.to_s])
      allow(Channel::Email).to receive_message_chain(:imap_enabled, :where, :find_each).and_yield(email_channel)
      allow(Channels::Email::ImapFetcher).to receive(:call).and_raise(StandardError.new('Connection timeout'))

      expect(Rails.logger).to receive(:error).with(/ImapFetchWorker failed for Channel::Email##{email_channel.id}/)

      expect { described_class.new.perform }.not_to raise_error
    end
  end
end

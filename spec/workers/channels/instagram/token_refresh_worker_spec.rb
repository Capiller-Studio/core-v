# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Instagram::TokenRefreshWorker, type: :worker do
  let(:account) { create(:account) }

  before do
    Channel::Instagram.destroy_all
  end

  describe '#perform' do
    it 'refreshes tokens for active Instagram channels expiring within 7 days' do
      expiring_channel = account.with_shard { create(:channel_instagram, account: account, status: :active, expires_at: 3.days.from_now) }
      valid_channel = account.with_shard { create(:channel_instagram, account: account, status: :active, expires_at: 30.days.from_now) }

      allow(Account).to receive_message_chain(:distinct, :pluck).with(:shard_key).and_return([account.shard_key])

      refreshed = false
      allow_any_instance_of(Channel::Instagram).to receive(:refresh_token!) do |instance|
        refreshed = true if instance.id == expiring_channel.id
      end

      described_class.new.perform

      expect(refreshed).to be(true)
    end

    it 'rescues errors per channel and logs' do
      failing_channel = account.with_shard { create(:channel_instagram, account: account, status: :active, expires_at: 3.days.from_now) }

      allow(Account).to receive_message_chain(:distinct, :pluck).with(:shard_key).and_return([account.shard_key])
      allow_any_instance_of(Channel::Instagram).to receive(:refresh_token!).and_raise(StandardError.new('Graph API error'))

      expect(Rails.logger).to receive(:error).with(/Failed to refresh Instagram token/).at_least(:once)

      expect { described_class.new.perform }.not_to raise_error
    end
  end
end

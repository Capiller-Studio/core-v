# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::MobilePushWorker, type: :worker do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:channel) { account.with_shard { create(:channel_mobile_widget, account: account, push_enabled: true) } }
  let!(:inbox) { account.with_shard { create(:inbox, account: account, channel: channel) } }
  let!(:conversation) { account.with_shard { create(:conversation, account: account, inbox: inbox) } }
  let!(:message) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, inbox: inbox, sender: user, content: 'Test push')
    end
  end

  describe '#perform' do
    it 'delegates push notification dispatch to PushNotifications::MobileDispatcher' do
      expect(PushNotifications::MobileDispatcher).to receive(:call).with(message: an_instance_of(Message))
      described_class.new.perform(account.id, message.id)
    end

    it 'returns gracefully if account cannot be found' do
      expect(PushNotifications::MobileDispatcher).not_to receive(:call)
      described_class.new.perform(SecureRandom.uuid, message.id)
    end

    it 'returns gracefully if message cannot be found' do
      expect(PushNotifications::MobileDispatcher).not_to receive(:call)
      described_class.new.perform(account.id, SecureRandom.uuid)
    end
  end
end

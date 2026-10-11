# frozen_string_literal: true

require "rails_helper"

RSpec.describe PushNotifications::MobileDispatcher do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:channel) do
    account.with_shard do
      create(:channel_mobile_widget, account: account, push_enabled: true)
    end
  end
  let!(:inbox) do
    account.with_shard do
      create(:inbox, account: account, channel: channel, primary_inbox: true)
    end
  end
  let!(:customer) do
    account.with_shard do
      create(:customer, account: account, name: "Sam Customer")
    end
  end
  let!(:customer_inbox) do
    account.with_shard do
      create(:customer_inbox, inbox: inbox, customer: customer)
    end
  end
  let!(:conversation) do
    account.with_shard do
      conv = create(:conversation, account: account, inbox: inbox)
      conv.conversation_members.create!(member: customer, account: account)
      conv
    end
  end
  let!(:outgoing_message) do
    account.with_shard do
      create(:message, account: account, conversation: conversation, inbox: inbox, sender: user, content: "Hello from agent", visibility: :global, status: :delivered)
    end
  end

  describe "#call" do
    it "dispatches push notifications to active devices" do
      device = account.with_shard do
        create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, push_token: "tok_ios_123", platform: :ios, push_provider: :apns)
      end

      expect(PushNotifications::ApnsSender).to receive(:call) do |args|
        expect(args[:channel]).to eq(channel)
        expect(args[:device]).to eq(device)
        expect(args[:payload][:body]).to eq("Hello from agent")
      end

      described_class.call(message: outgoing_message)
    end

    it "skips push when push_enabled is false" do
      account.with_shard { channel.update!(push_enabled: false) }
      expect(PushNotifications::ApnsSender).not_to receive(:call)
      described_class.call(message: outgoing_message)
    end

    it "skips push for private internal notes" do
      private_message = account.with_shard do
        create(:message, account: account, conversation: conversation, inbox: inbox, sender: user, content: "Secret", visibility: :personal)
      end
      expect(PushNotifications::ApnsSender).not_to receive(:call)
      described_class.call(message: private_message)
    end

    it "suppresses push notification when customer is actively online in the app" do
      account.with_shard do
        create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, push_token: "tok_ios_online", platform: :ios, push_provider: :apns)
      end
      allow(::Utilities::ActivityHelpers).to receive(:activity?).with(account.id, "Customer", customer.id).and_return(true)
      expect(PushNotifications::ApnsSender).not_to receive(:call)
      described_class.call(message: outgoing_message)
    end
  end
end

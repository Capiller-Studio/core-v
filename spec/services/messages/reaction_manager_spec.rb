# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::ReactionManager, type: :service do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:customer) { create(:customer, account: account) }
  let!(:message) { create(:message, account: account, conversation: conversation, sender: customer) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    allow(EventBroadcastWorker).to receive(:perform_async)
  end

  describe "reacting to a message" do
    it "adds a new reaction and broadcasts update" do
      expect(EventBroadcastWorker).to receive(:perform_async).with(anything, "message.updated", anything, account.id)

      expect {
        described_class.call(
          message: message,
          sender: customer,
          emoji: "👍",
          action: :react,
          reaction_name: "thumbs_up"
        )
      }.to change(MessageReaction, :count).by(1)

      reaction = message.reactions.last
      expect(reaction.emoji).to eq("👍")
      expect(reaction.reaction_name).to eq("thumbs_up")
      expect(reaction.sender).to eq(customer)
    end

    it "is idempotent for the same reaction and sender" do
      described_class.call(message: message, sender: customer, emoji: "👍", action: :react)

      expect {
        described_class.call(message: message, sender: customer, emoji: "👍", action: :react)
      }.not_to change(MessageReaction, :count)
    end
  end

  describe "unreacting from a message" do
    before do
      create(:message_reaction, account: account, message: message, sender: customer, emoji: "👍")
      create(:message_reaction, account: account, message: message, sender: customer, emoji: "❤️")
    end

    it "removes specific emoji reaction and broadcasts update" do
      expect(EventBroadcastWorker).to receive(:perform_async).with(anything, "message.updated", anything, account.id)

      expect {
        described_class.call(
          message: message,
          sender: customer,
          emoji: "👍",
          action: :unreact
        )
      }.to change(MessageReaction, :count).by(-1)

      expect(message.reactions.reload.pluck(:emoji)).to eq(["❤️"])
    end

    it "removes all reactions from sender if emoji is blank" do
      expect {
        described_class.call(
          message: message,
          sender: customer,
          emoji: nil,
          action: :unreact
        )
      }.to change(MessageReaction, :count).by(-2)
    end
  end
end

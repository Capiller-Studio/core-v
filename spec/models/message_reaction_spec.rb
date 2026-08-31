# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageReaction, type: :model do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:customer) { create(:customer, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: customer) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:message) }
    it { should belong_to(:sender) }
  end

  describe "validations" do
    let!(:existing_reaction) { create(:message_reaction, account: account, message: message, sender: customer, emoji: "like") }
    subject { existing_reaction }

    it { should validate_presence_of(:account_id) }
    it { should validate_presence_of(:message_id) }
    it { should validate_presence_of(:sender_id) }
    it { should validate_presence_of(:sender_type) }
    it { should validate_presence_of(:emoji) }
    it { should validate_uniqueness_of(:emoji).scoped_to(:message_id, :sender_type, :sender_id).ignoring_case_sensitivity }
  end

  describe "#event_payload" do
    let(:reaction) { create(:message_reaction, account: account, message: message, sender: customer, emoji: "❤️", reaction_name: "love") }

    it "returns serialized payload" do
      payload = reaction.event_payload
      expect(payload[:id]).to eq(reaction.id)
      expect(payload[:message_id]).to eq(message.id)
      expect(payload[:emoji]).to eq("❤️")
      expect(payload[:reaction_name]).to eq("love")
      expect(payload[:sender_id]).to eq(customer.id)
      expect(payload[:sender_type]).to eq("Customer")
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::ReactionHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, primary_inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:customer) { create(:customer, account: account) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, external_id: 'wamid_123', source: :whatsapp) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    create(:identity, customer: customer, identity_type: :whatsapp, identifier: '9876543210', account: account)
  end

  describe '#call' do
    let(:parsed_params) do
      {
        contacts: [{ "wa_id" => "9876543210", "profile" => { "name" => "WA Customer" } }],
        messages: [{
          id: "wamid_reaction_1",
          from: "9876543210",
          type: "reaction",
          reaction: {
            message_id: "wamid_123",
            emoji: "👍"
          }
        }]
      }
    end

    let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params) }

    it 'processes reaction with scoped inbox and identity-resolved customer' do
      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: customer,
        emoji: '👍',
        action: :react,
        external_id: 'wamid_reaction_1'
      )

      service.call
    end

    it 'assigns account as sender when event is from business full_phone_number' do
      business_phone_digits = whatsapp_channel.full_phone_number.to_s.gsub(/\D/, "")
      echo_params = {
        contacts: [],
        messages: [{
          id: "wamid_reaction_echo",
          from: business_phone_digits,
          reaction: { message_id: "wamid_123", emoji: "❤️" }
        }]
      }

      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: account,
        emoji: '❤️',
        action: :react,
        external_id: 'wamid_reaction_echo'
      )

      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: echo_params).call
    end

    it 'does nothing if message belongs to a different channel/inbox' do
      other_inbox = create(:inbox, account: account)
      create(:message, account: account, inbox: other_inbox, external_id: 'other_wamid', source: :instagram_direct_message)
      
      other_params = {
        contacts: [{ "wa_id" => "9876543210" }],
        messages: [{
          id: "wamid_reaction_2",
          from: "9876543210",
          reaction: { message_id: "other_wamid", emoji: "👍" }
        }]
      }

      expect(Messages::ReactionManager).not_to receive(:call)
      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: other_params).call
    end

    it 'creates customer if identity and customer_inbox do not exist' do
      new_params = {
        contacts: [{ "wa_id" => "999888777", "profile" => { "name" => "New WA User" } }],
        messages: [{
          id: "wamid_reaction_3",
          from: "999888777",
          reaction: { message_id: "wamid_123", emoji: "❤️" }
        }]
      }

      expect {
        described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: new_params).call
      }.to change(Customer, :count).by(1)

      expect(account.identities.exists?(identity_type: :whatsapp, identifier: '999888777')).to be true
    end

    it 'handles unreact when emoji is blank' do
      unreact_params = {
        contacts: [{ "wa_id" => "9876543210" }],
        messages: [{
          id: "wamid_reaction_4",
          from: "9876543210",
          reaction: { message_id: "wamid_123", emoji: "" }
        }]
      }

      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: customer,
        emoji: "",
        action: :unreact,
        external_id: "wamid_reaction_4"
      )

      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: unreact_params).call
    end

    it 'does nothing if target message_id is blank' do
      blank_params = {
        messages: [{
          id: "wamid_reaction_blank",
          from: "9876543210",
          reaction: { message_id: nil, emoji: "👍" }
        }]
      }

      expect(Messages::ReactionManager).not_to receive(:call)
      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: blank_params).call
    end
  end
end

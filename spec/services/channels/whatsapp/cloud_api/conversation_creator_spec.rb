# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::ConversationCreator do
  let(:whatsapp_channel) { double('Channel::Whatsapp', account: account, primary_inbox: inbox, inboxes: [inbox], phone_number_id: 'pn123') }
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox') }
  let(:parsed_params) do
    {
      contacts: [{ "wa_id" => "987", "profile" => { "name" => "WA User" }, "language" => "portuguese" }],
      messages: [{ type: "text", from: "987", id: "msg_wa_1" }]
    }
  end

  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params, account: account) }

  before do
    allow(account).to receive(:with_shard).and_yield
    allow(account).to receive_message_chain(:messages, :where, :find_by).and_return(nil)

    stub_const('RedisUtilities::Helpers', double('RedisHelpers'))
    allow(RedisUtilities::Helpers).to receive(:get).and_return(false)
    allow(RedisUtilities::Helpers).to receive(:set)
    allow(RedisUtilities::Helpers).to receive(:delete)

    stub_const('RedisUtilities::MutexHelpers', double('MutexHelpers'))
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#call' do
    let(:customer) { double('Customer', locale: 'en') }
    let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::Whatsapp::CloudApi::MessageCreator', double('MessageCreator'))

      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)
      allow(account).to receive_message_chain(:identities, :exists?).and_return(false)
      allow(account).to receive_message_chain(:identities, :create!)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::Whatsapp::CloudApi::MessageCreator).to receive(:call)
    end

    it 'creates customer, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(
          external_id: "987",
          full_phone_number: "+987",
          params: hash_including(locale: "pt")
        )
      )

      expect(account.identities).to receive(:create!).with(
        hash_including(identity_type: :whatsapp, identifier: "987", name: nil)
      )

      expect(account.conversations).to receive(:create!).with(
        hash_including(source: :whatsapp)
      )

      expect(Channels::Whatsapp::CloudApi::MessageCreator).to receive(:call).with(
        hash_including(whatsapp_channel: whatsapp_channel, message_type: "text", parsed_message: parsed_params)
      )

      service.call
    end

    context 'when messages array is empty or nil' do
      let(:parsed_params) { { messages: [] } }

      it 'aborts early without error and without creating customer or message' do
        expect(Customers::CustomerCreator).not_to receive(:call)
        expect(Channels::Whatsapp::CloudApi::MessageCreator).not_to receive(:call)

        expect { service.call }.not_to raise_error
      end
    end

    context 'when message has already been processed (duplicate external_id)' do
      let(:existing_msg) { double('Message', id: 'msg_existing') }

      before do
        allow(account).to receive_message_chain(:messages, :where, :find_by).and_return(existing_msg)
      end

      it 'returns early without creating duplicate records' do
        expect(Customers::CustomerCreator).not_to receive(:call)
        expect(Channels::Whatsapp::CloudApi::MessageCreator).not_to receive(:call)

        service.call
      end
    end

    context 'when message creation is currently locked in Redis' do
      before do
        allow(RedisUtilities::Helpers).to receive(:get).and_return(true)
      end

      it 'returns early to prevent concurrency race conditions' do
        expect(Customers::CustomerCreator).not_to receive(:call)
        expect(Channels::Whatsapp::CloudApi::MessageCreator).not_to receive(:call)

        service.call
      end
    end

    context 'with reaction message type' do
      let(:parsed_params) do
        {
          contacts: [{ "wa_id" => "987", "profile" => { "name" => "WA User" } }],
          messages: [{ type: "reaction", from: "987", id: "msg_wa_reaction_1", reaction: { message_id: "wamid_orig", emoji: "👍" } }]
        }
      end

      it 'delegates to Channels::Whatsapp::CloudApi::ReactionHandler' do
        expect(Channels::Whatsapp::CloudApi::ReactionHandler).to receive(:call).with(
          whatsapp_channel: whatsapp_channel,
          parsed_params: parsed_params
        )

        service.call
      end
    end

    context 'with protocol edited_message type' do
      let(:parsed_params) do
        {
          messages: [{
            type: "protocol",
            from: "987",
            protocol_message: {
              type: "edited_message",
              message_id: "wamid_orig",
              edited_message: { text: { body: "Edited" } }
            }
          }]
        }
      end

      it 'delegates to Channels::Whatsapp::CloudApi::EditHandler' do
        expect(Channels::Whatsapp::CloudApi::EditHandler).to receive(:call).with(
          whatsapp_channel: whatsapp_channel,
          parsed_params: parsed_params
        )

        service.call
      end
    end

    context 'with protocol revocation type' do
      let(:parsed_params) do
        {
          messages: [{
            type: "protocol",
            from: "987",
            protocol_message: {
              type: "revocation",
              message_id: "wamid_orig"
            }
          }]
        }
      end

      it 'delegates to Channels::Whatsapp::CloudApi::UnsendHandler' do
        expect(Channels::Whatsapp::CloudApi::UnsendHandler).to receive(:call).with(
          whatsapp_channel: whatsapp_channel,
          parsed_params: parsed_params
        )

        service.call
      end
    end

    context 'with unsupported message types' do
      %w[request_welcome ephemeral unsupported].each do |unsupported_type|
        it "does nothing for #{unsupported_type} message type" do
          params = {
            contacts: [{ "wa_id" => "987", "profile" => { "name" => "WA User" } }],
            messages: [{ type: unsupported_type, from: "987", id: "msg_wa_1" }]
          }
          srv = described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: params, account: account)
          expect(srv).not_to receive(:find_inbox)
          srv.call
        end
      end
    end
  end
end

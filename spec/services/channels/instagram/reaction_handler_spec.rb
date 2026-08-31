# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Instagram::ReactionHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:instagram_channel) { create(:channel_instagram, account: account, primary_inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:customer) { create(:customer, account: account) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, external_id: 'ig_mid_123', source: :instagram_direct_message) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    create(:identity, customer: customer, identity_type: :instagram, identifier: 'ig_user_456', account: account)
  end

  describe '#call' do
    let(:parsed_message) do
      double(
        'Parser::InstagramMessageParser',
        sender_id: 'ig_user_456',
        reaction_mid: 'ig_mid_123',
        reaction_emoji: '❤️',
        reaction_action: 'react',
        reaction_name: 'love',
        echo?: false
      )
    end

    let(:service) { described_class.new(channel: instagram_channel, parsed_message: parsed_message) }

    it 'processes reaction with scoped inbox and identity-resolved customer' do
      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: customer,
        emoji: '❤️',
        action: :react,
        reaction_name: 'love',
        external_id: 'ig_mid_123'
      )

      service.call
    end

    it 'assigns account as sender when event is an echo or sender matches channel instagram_id' do
      parsed_echo = double(
        'Parser::InstagramMessageParser',
        sender_id: instagram_channel.instagram_id,
        reaction_mid: 'ig_mid_123',
        reaction_emoji: '❤️',
        reaction_action: 'react',
        reaction_name: 'love',
        echo?: true
      )

      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: account,
        emoji: '❤️',
        action: :react,
        reaction_name: 'love',
        external_id: 'ig_mid_123'
      )

      described_class.new(channel: instagram_channel, parsed_message: parsed_echo).call
    end

    it 'does nothing if message belongs to a different channel/inbox' do
      other_inbox = create(:inbox, account: account)
      create(:message, account: account, inbox: other_inbox, external_id: 'other_ig_mid', source: :whatsapp)
      
      parsed_diff = double(
        'Parser::InstagramMessageParser',
        sender_id: 'ig_user_456',
        reaction_mid: 'other_ig_mid',
        reaction_emoji: '❤️',
        reaction_action: 'react',
        reaction_name: 'love',
        echo?: false
      )

      expect(Messages::ReactionManager).not_to receive(:call)
      described_class.new(channel: instagram_channel, parsed_message: parsed_diff).call
    end

    it 'creates customer if identity and customer_inbox do not exist' do
      parsed_new = double(
        'Parser::InstagramMessageParser',
        sender_id: 'new_ig_user_789',
        reaction_mid: 'ig_mid_123',
        reaction_emoji: '🔥',
        reaction_action: 'react',
        reaction_name: 'fire',
        echo?: false
      )

      allow_any_instance_of(described_class).to receive(:fetch_customer_details).and_return({
        "name" => "New IG User",
        "username" => "new_ig_user",
        "profile_pic" => "http://example.com/pic.jpg"
      })

      expect {
        described_class.new(channel: instagram_channel, parsed_message: parsed_new).call
      }.to change(Customer, :count).by(1)

      expect(account.identities.exists?(identity_type: :instagram, identifier: 'new_ig_user_789')).to be true
    end

    it 'handles unreact action' do
      parsed_unreact = double(
        'Parser::InstagramMessageParser',
        sender_id: 'ig_user_456',
        reaction_mid: 'ig_mid_123',
        reaction_emoji: '❤️',
        reaction_action: 'unreact',
        reaction_name: 'love',
        echo?: false
      )

      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: customer,
        emoji: '❤️',
        action: :unreact,
        reaction_name: 'love',
        external_id: 'ig_mid_123'
      )

      described_class.new(channel: instagram_channel, parsed_message: parsed_unreact).call
    end

    it 'returns nil gracefully if mid or sender_id is blank' do
      parsed_blank = double(
        'Parser::InstagramMessageParser',
        sender_id: nil,
        reaction_mid: nil,
        echo?: false
      )

      expect(Messages::ReactionManager).not_to receive(:call)
      described_class.new(channel: instagram_channel, parsed_message: parsed_blank).call
    end

    it 'calls authorization_error! when Instagram API returns token expired error (code 190)' do
      parsed_new = double(
        'Parser::InstagramMessageParser',
        sender_id: 'new_ig_user_err',
        reaction_mid: 'ig_mid_123',
        reaction_emoji: '🔥',
        reaction_action: 'react',
        reaction_name: 'fire',
        echo?: false
      )

      response_double = double(
        'HTTParty::Response',
        success?: false,
        code: 400,
        parsed_response: { 'error' => { 'code' => 190, 'message' => 'Error validating access token' } }
      )
      allow(HTTParty).to receive(:get).and_return(response_double)

      expect(instagram_channel).to receive(:authorization_error!)
      described_class.new(channel: instagram_channel, parsed_message: parsed_new).call
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::FacebookPages::ReactionHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:facebook_channel) do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
    create(:channel_facebook_page, account: account, primary_inbox: inbox, page_identifier: 'fb_page_999')
  end
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:customer) { create(:customer, account: account) }
  let!(:message) { create(:message, account: account, conversation: conversation, external_id: 'fb_mid_123', source: :facebook_message) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
    create(:identity, customer: customer, identity_type: :facebook, identifier: 'fb_user_456', account: account)
  end

  describe '#call' do
    let(:parsed_message) do
      double(
        'Parser::FacebookMessageParser',
        sender_id: 'fb_user_456',
        reaction_mid: 'fb_mid_123',
        reaction_emoji: '👍',
        reaction_action: 'react',
        reaction_name: 'like',
        echo?: false
      )
    end

    let(:service) { described_class.new(channel: facebook_channel, parsed_message: parsed_message) }

    it 'processes reaction with scoped inbox and identity-resolved customer' do
      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: customer,
        emoji: '👍',
        action: :react,
        reaction_name: 'like',
        external_id: 'fb_mid_123'
      )

      service.call
    end

    it 'assigns account as sender when event is an echo or sender matches channel page_identifier' do
      parsed_echo = double(
        'Parser::FacebookMessageParser',
        sender_id: 'fb_page_999',
        reaction_mid: 'fb_mid_123',
        reaction_emoji: '👍',
        reaction_action: 'react',
        reaction_name: 'like',
        echo?: true
      )

      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: account,
        emoji: '👍',
        action: :react,
        reaction_name: 'like',
        external_id: 'fb_mid_123'
      )

      described_class.new(channel: facebook_channel, parsed_message: parsed_echo).call
    end

    it 'does nothing if message belongs to a different channel/inbox' do
      other_inbox = create(:inbox, account: account)
      create(:message, account: account, inbox: other_inbox, external_id: 'other_mid_123', source: :instagram_direct_message)
      
      parsed_diff = double(
        'Parser::FacebookMessageParser',
        sender_id: 'fb_user_456',
        reaction_mid: 'other_mid_123',
        reaction_emoji: '👍',
        reaction_action: 'react',
        reaction_name: 'like',
        echo?: false
      )

      expect(Messages::ReactionManager).not_to receive(:call)
      described_class.new(channel: facebook_channel, parsed_message: parsed_diff).call
    end

    it 'creates customer if identity and customer_inbox do not exist' do
      parsed_new = double(
        'Parser::FacebookMessageParser',
        sender_id: 'new_fb_user_789',
        reaction_mid: 'fb_mid_123',
        reaction_emoji: '❤️',
        reaction_action: 'react',
        reaction_name: 'love',
        echo?: false
      )

      allow_any_instance_of(described_class).to receive(:fetch_customer_details).and_return({
        "first_name" => "John",
        "last_name" => "Doe",
        "profile_pic" => "http://example.com/fb_pic.jpg"
      })

      expect {
        described_class.new(channel: facebook_channel, parsed_message: parsed_new).call
      }.to change(Customer, :count).by(1)

      expect(account.identities.exists?(identity_type: :facebook, identifier: 'new_fb_user_789')).to be true
    end

    it 'handles unreact action' do
      parsed_unreact = double(
        'Parser::FacebookMessageParser',
        sender_id: 'fb_user_456',
        reaction_mid: 'fb_mid_123',
        reaction_emoji: '👍',
        reaction_action: 'unreact',
        reaction_name: 'like',
        echo?: false
      )

      expect(Messages::ReactionManager).to receive(:call).with(
        message: message,
        sender: customer,
        emoji: '👍',
        action: :unreact,
        reaction_name: 'like',
        external_id: 'fb_mid_123'
      )

      described_class.new(channel: facebook_channel, parsed_message: parsed_unreact).call
    end

    it 'returns nil and does not process when mid or sender_id is blank' do
      parsed_blank = double(
        'Parser::FacebookMessageParser',
        sender_id: nil,
        reaction_mid: nil,
        echo?: false
      )

      expect(Messages::ReactionManager).not_to receive(:call)
      expect(described_class.new(channel: facebook_channel, parsed_message: parsed_blank).call).to be_nil
    end

    it 'calls authorization_error! when Koala raises AuthenticationError during customer fetch' do
      parsed_new = double(
        'Parser::FacebookMessageParser',
        sender_id: 'new_fb_user_err',
        reaction_mid: 'fb_mid_123',
        reaction_emoji: '❤️',
        reaction_action: 'react',
        reaction_name: 'love',
        echo?: false
      )

      allow_any_instance_of(Koala::Facebook::API).to receive(:get_object).and_raise(
        Koala::Facebook::AuthenticationError.new(190, "Session has expired")
      )

      expect(facebook_channel).to receive(:authorization_error!)
      described_class.new(channel: facebook_channel, parsed_message: parsed_new).call
    end
  end
end

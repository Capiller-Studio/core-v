# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebWidgetChannel, type: :channel do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_web_widget, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: channel) }
  let(:customer) { create(:customer, account: account) }
  let(:customer_inbox) { create(:customer_inbox, customer: customer, inbox: inbox) }
  let(:connection_token) { customer_inbox.connection_token }

  before do
    allow(::Utilities::ActivityHelpers).to receive(:update_activity)
  end

  describe '#subscribed' do
    context 'with valid connection_token' do
      it 'subscribes and streams from the connection_token' do
        subscribe(connection_token: connection_token)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from(connection_token)
        expect(::Utilities::ActivityHelpers).to have_received(:update_activity).with(
          account.id,
          'Customer',
          customer.id
        )
      end
    end

    context 'with invalid or missing connection_token' do
      it 'subscribes to stream nil or empty gracefully' do
        subscribe(connection_token: 'invalid_token')

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from('invalid_token')
      end
    end
  end

  describe '#ping and #activity' do
    before do
      subscribe(connection_token: connection_token)
    end

    it 'updates customer activity on ping' do
      perform :ping
      expect(::Utilities::ActivityHelpers).to have_received(:update_activity).with(
        account.id,
        'Customer',
        customer.id
      ).at_least(:once)
    end

    it 'updates customer activity on activity' do
      perform :activity
      expect(::Utilities::ActivityHelpers).to have_received(:update_activity).with(
        account.id,
        'Customer',
        customer.id
      ).at_least(:once)
    end
  end

  describe '#typing' do
    let(:user) { create(:user) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :active) }

    before do
      subscribe(connection_token: connection_token)
      create(:conversation_member, conversation: conversation, member: user, account: account)
      create(:conversation_member, conversation: conversation, member: customer, account: account)
    end

    it 'broadcasts typing event to assigned conversation users' do
      expect(ActionCable.server).to receive(:broadcast).with(
        user.connection_token,
        hash_including(
          event: 'typing',
          conversation_id: conversation.id,
          sender_type: 'Customer',
          sender_id: customer.id,
          status: 'on'
        )
      )

      perform :typing, { 'status' => 'on' }
    end

    it 'does nothing if no active conversation exists' do
      conversation.update!(status: :resolved)

      expect(ActionCable.server).not_to receive(:broadcast)
      perform :typing, { 'status' => 'on' }
    end
  end

  describe '#read' do
    let(:user) { create(:user) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :active) }
    let!(:outgoing_message) { create(:message, account: account, conversation: conversation, sender: user, status: :sent) }

    before do
      subscribe(connection_token: connection_token)
      create(:conversation_member, conversation: conversation, member: customer, account: account)
      allow(UnreadCounts::Reset).to receive(:call)
    end

    it 'marks outgoing messages as read, resets unread counts, and updates activity' do
      perform :read, { 'conversation_id' => conversation.id, 'message_id' => outgoing_message.id }

      outgoing_message.reload
      expect(outgoing_message.status).to eq('read')
      expect(UnreadCounts::Reset).to have_received(:call).with(conversation, customer)
      expect(::Utilities::ActivityHelpers).to have_received(:update_activity).with(
        account.id,
        'Customer',
        customer.id
      ).at_least(:once)
    end
  end
end

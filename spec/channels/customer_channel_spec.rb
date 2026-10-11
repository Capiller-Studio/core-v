# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomerChannel, type: :channel do
  let!(:account) { create(:account) }
  let!(:channel) { account.with_shard { create(:channel_mobile_widget, account: account) } }
  let!(:inbox) { account.with_shard { create(:inbox, account: account, channel: channel) } }
  let!(:customer) { account.with_shard { create(:customer, account: account) } }
  let!(:customer_inbox) { account.with_shard { create(:customer_inbox, customer: customer, inbox: inbox) } }
  let(:connection_token) { customer_inbox.connection_token }

  before do
    allow(::Utilities::ActivityHelpers).to receive(:update_activity)
  end

  describe '#subscribed' do
    context 'with valid connection_token' do
      it 'subscribes and streams from the connection_token and tracks activity' do
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

    context 'with invalid connection_token' do
      it 'rejects subscription when connection_token does not exist' do
        subscribe(connection_token: 'invalid_tok')

        expect(subscription).to be_rejected
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
    let!(:user) { create(:user, connection_token: 'agent_conn_tok_1') }
    let!(:conversation) do
      account.with_shard do
        conv = create(:conversation, account: account, inbox: inbox, status: :active)
        conv.conversation_members.create!(member: customer, account: account)
        conv.conversation_members.create!(member: user, account: account)
        conv
      end
    end

    before do
      subscribe(connection_token: connection_token)
    end

    it 'broadcasts typing state to connected agent tokens' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'agent_conn_tok_1',
        hash_including(
          event: 'typing',
          conversation_id: conversation.id,
          sender_type: 'Customer',
          status: 'typing'
        )
      )

      perform :typing, { 'status' => 'typing' }
    end
  end

  describe '#read' do
    let!(:user) { create(:user) }
    let!(:conversation) do
      account.with_shard do
        conv = create(:conversation, account: account, inbox: inbox, status: :active)
        conv.conversation_members.create!(member: customer, account: account)
        conv
      end
    end
    let!(:agent_message) do
      account.with_shard do
        create(:message, account: account, conversation: conversation, inbox: inbox, sender: user, content: 'Agent msg', status: :sent)
      end
    end

    before do
      subscribe(connection_token: connection_token)
    end

    it 'marks the specified message as read and updates activity' do
      perform :read, { 'message_id' => agent_message.id, 'conversation_id' => conversation.id }

      account.with_shard do
        expect(agent_message.reload.status).to eq('read')
      end
      expect(::Utilities::ActivityHelpers).to have_received(:update_activity).at_least(:once)
    end
  end
end

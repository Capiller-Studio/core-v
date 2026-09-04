# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::DeliveryWorker, type: :worker do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user) }
  let(:outgoing_message) { create(:message, account: account, conversation: conversation, sender: user) }
  let(:customer) { create(:customer, account: account) }
  let(:incoming_message) { create(:message, account: account, conversation: conversation, sender: customer) }

  describe '#perform' do
    it 'calls Channels::ServicePicker for outgoing messages' do
      expect(Channels::ServicePicker).to receive(:call).with(
        conversation: conversation,
        message: outgoing_message
      )

      described_class.new.perform(account.id, outgoing_message.id)
    end

    it 'delivers multiple outgoing messages sequentially in the exact specified order' do
      second_outgoing = create(:message, account: account, conversation: conversation, sender: user)

      # Ensure strict ordering of deliveries
      expect(Channels::ServicePicker).to receive(:call).with(
        conversation: conversation,
        message: outgoing_message
      ).ordered

      expect(Channels::ServicePicker).to receive(:call).with(
        conversation: conversation,
        message: second_outgoing
      ).ordered

      described_class.new.perform(account.id, [outgoing_message.id, second_outgoing.id])
    end

    it 'does not call Channels::ServicePicker for incoming messages' do
      expect(Channels::ServicePicker).not_to receive(:call)

      described_class.new.perform(account.id, incoming_message.id)
    end

    it 'returns early if account or message is not found' do
      expect(Channels::ServicePicker).not_to receive(:call)

      described_class.new.perform(SecureRandom.uuid, outgoing_message.id)
    end
  end
end

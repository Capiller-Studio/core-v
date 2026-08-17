# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sla::EventProcessorWorker, type: :worker do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#perform' do
    it 'calls Sla::EventProcessor for existing conversation' do
      expect(Sla::EventProcessor).to receive(:call).with(conversation: conversation)

      described_class.new.perform(conversation.id)
    end

    it 'returns early if conversation is not found' do
      expect(Sla::EventProcessor).not_to receive(:call)

      described_class.new.perform(SecureRandom.uuid)
    end
  end
end

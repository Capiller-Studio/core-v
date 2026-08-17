# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::StatusUpdateWorker, type: :worker do
  let(:account) { create(:account) }

  describe '#perform' do
    it 'calls Messages::StatusUpdater with symbolized/indifferent access params' do
      expect(Messages::StatusUpdater).to receive(:call).with(
        account_id: account.id,
        status: 'delivered',
        params: hash_including('message_id' => '123')
      )

      described_class.new.perform(account.id, 'delivered', { 'message_id' => '123' })
    end
  end
end

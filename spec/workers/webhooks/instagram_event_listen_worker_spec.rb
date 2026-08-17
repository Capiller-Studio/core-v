# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::InstagramEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:instagram_id) { "ig_#{SecureRandom.hex(4)}" }
  let(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: instagram_id, status: :active) }

  before do
    GlobalRouting.create!(
      route_type: 'instagram',
      route_value: instagram_id,
      account: account,
      shard_key: account.shard_key
    )
  end

  describe '#perform' do
    it 'calls Channels::Instagram::EventListener for incoming Instagram webhook' do
      webhook = create(:webhook_incoming,
        source: 'instagram',
        payload: {
          'entry' => [
            {
              'id' => instagram_id,
              'messaging' => [
                { 'message' => { 'text' => 'Hello Instagram' } }
              ]
            }
          ]
        }
      )

      expect(Channels::Instagram::EventListener).to receive(:call).with(
        instagram_channel: instagram_channel,
        payload: hash_including(:entry)
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end

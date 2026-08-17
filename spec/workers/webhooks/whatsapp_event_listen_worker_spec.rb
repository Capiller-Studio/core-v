# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::WhatsappEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, status: :active) }

  describe '#perform' do
    it 'routes whatsapp business account messages via GlobalRouting and calls Channels::Whatsapp::CloudApi::EventListener' do
      phone_digits = whatsapp_channel.full_phone_number.sub(/\A\+/, '')
      webhook = create(:webhook_incoming,
        source: 'whatsapp',
        payload: {
          'object' => 'whatsapp_business_account',
          'entry' => [
            {
              'changes' => [
                {
                  'value' => {
                    'metadata' => {
                      'display_phone_number' => phone_digits,
                      'phone_number_id' => whatsapp_channel.phone_number_id
                    },
                    'messages' => [
                      { 'text' => { 'body' => 'Hello WhatsApp' } }
                    ]
                  }
                }
              ]
            }
          ]
        }
      )

      expect(Channels::Whatsapp::CloudApi::EventListener).to receive(:call).with(
        whatsapp_channel: whatsapp_channel,
        params: hash_including('object' => 'whatsapp_business_account')
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end

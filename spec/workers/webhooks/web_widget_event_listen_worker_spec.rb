# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::WebWidgetEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_web_widget, account: account, status: :active) }

  before do
    allow_any_instance_of(Webhook::Incoming).to receive(:route_params).and_return(
      { account_id: account.id, channel_id: web_widget.id }
    )
    stub_const('Channels::WebWidget::EventListener', Class.new { def self.call(*); end })
  end

  describe '#perform' do
    it 'calls Channels::WebWidget::EventListener for incoming web widget event' do
      webhook = create(:webhook_incoming,
        source: 'web_widget',
        event_type: 'message.created',
        payload: {
          'message' => { 'content' => 'Hello widget' }
        }
      )

      expect(Channels::WebWidget::EventListener).to receive(:call).with(
        channel: web_widget,
        payload: hash_including(:message),
        event_type: 'message.created'
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end

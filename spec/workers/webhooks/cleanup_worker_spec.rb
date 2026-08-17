# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::CleanupWorker, type: :worker do
  describe '#perform' do
    it 'deletes processed incoming webhooks older than 14 days' do
      old_webhook = create(:webhook_incoming, status: :processed, created_at: 15.days.ago)
      recent_webhook = create(:webhook_incoming, status: :processed, created_at: 2.days.ago)
      pending_webhook = create(:webhook_incoming, status: :pending, created_at: 20.days.ago)

      described_class.new.perform

      expect(Webhook::Incoming.exists?(old_webhook.id)).to be(false)
      expect(Webhook::Incoming.exists?(recent_webhook.id)).to be(true)
      expect(Webhook::Incoming.exists?(pending_webhook.id)).to be(true)
    end
  end
end

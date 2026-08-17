# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::RetryFailedWorker, type: :worker do
  let(:failed_stripe_webhook) { create(:webhook_incoming, source: 'stripe', status: :failed) }

  describe '#perform' do
    context 'when webhook_id is provided' do
      it 'retries the specific failed webhook' do
        expect(Webhooks::StripeEventListenWorker).to receive(:perform_async).with(failed_stripe_webhook.id)

        described_class.new.perform(failed_stripe_webhook.id)
      end
    end

    context 'when no arguments are provided (sweep)' do
      it 'sweeps failed webhooks and re-enqueues their listener workers' do
        allow_any_instance_of(described_class).to receive(:fetch_active_webhook_ids).and_return(Set.new)
        expect(Webhooks::StripeEventListenWorker).to receive(:perform_async).with(failed_stripe_webhook.id)

        described_class.new.perform

        failed_stripe_webhook.reload
        expect(failed_stripe_webhook.fail_safe_retries).to eq(1)
      end

      it 'marks webhooks permanently failed after MAX_FAIL_SAFE_RETRIES' do
        failed_stripe_webhook.update_columns(fail_safe_retries: 3)
        allow_any_instance_of(described_class).to receive(:fetch_active_webhook_ids).and_return(Set.new)
        expect(Webhooks::StripeEventListenWorker).not_to receive(:perform_async)

        described_class.new.perform

        failed_stripe_webhook.reload
        expect(failed_stripe_webhook.status).to eq('permanently_failed')
      end
    end
  end
end

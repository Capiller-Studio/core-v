# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemLogs::EventKeys do
  describe 'Constants' do
    it 'defines non-empty unique string keys' do
      expect(described_class::ALL).to be_an(Array)
      expect(described_class::ALL).not_to be_empty

      described_class::ALL.each do |key|
        expect(key).to be_a(String)
        expect(key).not_to be_blank
        expect(key).to match(/\A[a-z0-9_.]+\z/)
      end

      expect(described_class::ALL.uniq.size).to eq(described_class::ALL.size)
    end

    it 'includes core webhook and system event keys' do
      expect(described_class::WEBHOOK_FACEBOOK_AUTH_ERROR).to eq('webhook.facebook.auth_error')
      expect(described_class::WEBHOOK_WHATSAPP_ERROR).to eq('webhook.whatsapp.error')
      expect(described_class::CHANNEL_REAUTHORIZATION_REQUIRED).to eq('channel.reauthorization_required')
      expect(described_class::BILLING_PAYMENT_FAILED).to eq('billing.payment_failed')
      expect(described_class::SYSTEM_PRUNED_LOGS).to eq('system.pruned_logs')
    end
  end
end

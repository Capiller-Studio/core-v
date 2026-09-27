# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemLogWorker, type: :worker do
  let!(:account) { create(:account) }

  describe '#perform' do
    let(:params) do
      {
        event_key: 'billing.payment_failed',
        level: 'error',
        account_id: account.id,
        message: 'Payment of $50 failed for Monthly plan',
        payload: { 'error' => 'Card declined', 'amount' => 50.0 },
        metadata: { 'source' => 'cron' }
      }
    end

    it 'creates a SystemLog entry with provided parameters' do
      expect {
        described_class.new.perform(params)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.latest.first
      expect(log.account_id).to eq(account.id)
      expect(log.event_key).to eq('billing.payment_failed')
      expect(log.log_level).to eq('error')
      expect(log.message).to eq('Payment of $50 failed for Monthly plan')
      expect(log.payload).to eq({ 'error' => 'Card declined', 'amount' => 50.0 })
      expect(log.metadata).to eq({ 'source' => 'cron' })
    end

    it 'creates system log when account_id is nil (system-wide event)' do
      params[:account_id] = nil

      expect {
        described_class.new.perform(params)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.latest.first
      expect(log.account).to be_nil
      expect(log.event_key).to eq('billing.payment_failed')
    end

    it 'handles non-existent account_id gracefully without raising error' do
      params[:account_id] = SecureRandom.uuid

      expect {
        described_class.new.perform(params)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.latest.first
      expect(log.account).to be_nil
    end

    it 'rescues errors gracefully without raising' do
      allow(SystemLog).to receive(:create!).and_raise(StandardError.new('DB error'))
      expect(Rails.logger).to receive(:error).with(/SystemLogWorker failed: DB error/)

      expect {
        described_class.new.perform(params)
      }.not_to raise_error
    end
  end
end

require 'rails_helper'

RSpec.describe SystemLog, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account).optional }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:event_key) }
    it { is_expected.to validate_presence_of(:log_level) }
  end

  describe '.log_event' do
    let(:account) { create(:account) }

    it 'enqueues SystemLogWorker with JSON payload' do
      expect(SystemLogWorker).to receive(:perform_async).with(
        hash_including(
          'event_key'  => 'billing.payment_failed',
          'level'      => 'error',
          'account_id' => account.id,
          'message'    => 'Payment failed',
          'payload'    => { 'amount' => 50.0 },
          'metadata'   => { 'source' => 'cron' }
        )
      )

      described_class.log_event(
        'billing.payment_failed',
        level: :error,
        account: account,
        message: 'Payment failed',
        payload: { amount: 50.0 },
        metadata: { source: 'cron' }
      )
    end
  end

  describe '.log_event!' do
    let(:account) { create(:account) }

    it 'creates a SystemLog synchronously in the database' do
      expect {
        described_class.log_event!(
          'billing.payment_succeeded',
          level: :info,
          account: account,
          message: 'Payment completed'
        )
      }.to change(described_class, :count).by(1)

      log = described_class.latest.first
      expect(log.event_key).to eq('billing.payment_succeeded')
      expect(log.log_level).to eq('info')
      expect(log.account).to eq(account)
    end

    it 'handles database errors gracefully without raising' do
      allow(described_class).to receive(:create!).and_raise(ActiveRecord::StatementInvalid.new('DB error'))
      expect(Rails.logger).to receive(:error).with(/SystemLog.log_event! failed/)

      expect {
        described_class.log_event!('some.event')
      }.not_to raise_error
    end
  end
end

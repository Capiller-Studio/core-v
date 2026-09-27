# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentPolicies::QueueDrainWorker do
  describe '#perform' do
    let(:account_id) { 'acc-1' }
    let(:inbox_id) { 'inbox-1' }
    let(:lock_key) { "QUEUE_DRAIN_LOCK:#{account_id}:#{inbox_id}" }

    it 'acquires distributed lock and delegates to QueueDrainer' do
      expect(RedisUtilities::MutexHelpers).to receive(:locked?).with(lock_key).and_return(false)
      expect(RedisUtilities::MutexHelpers).to receive(:with_lock).with(lock_key, timeout: 15.seconds, wait_timeout: 0.seconds).and_yield
      expect(AssignmentPolicies::QueueDrainer).to receive(:call).with(account_id: account_id, inbox_id: inbox_id)

      described_class.new.perform(account_id, inbox_id)
    end

    it 'skips execution gracefully if another worker holds the lock' do
      expect(RedisUtilities::MutexHelpers).to receive(:locked?).with(lock_key).and_return(true)
      expect(AssignmentPolicies::QueueDrainer).not_to receive(:call)

      expect { described_class.new.perform(account_id, inbox_id) }.not_to raise_error
    end

    it 'handles MutexLockError gracefully when lock acquisition fails concurrently' do
      expect(RedisUtilities::MutexHelpers).to receive(:locked?).with(lock_key).and_return(false)
      expect(RedisUtilities::MutexHelpers).to receive(:with_lock).and_raise(MutexLockError.new('Locked'))
      expect(AssignmentPolicies::QueueDrainer).not_to receive(:call)

      expect { described_class.new.perform(account_id, inbox_id) }.not_to raise_error
    end
  end
end

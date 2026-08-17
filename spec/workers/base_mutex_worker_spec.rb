# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseMutexWorker, type: :worker do
  it 'configures Sidekiq retry limit and default queue' do
    expect(described_class.get_sidekiq_options['retry']).to eq(BaseMutexWorker::MUTEX_LOCK_RETRY_LIMIT)
    expect(described_class.get_sidekiq_options['queue']).to eq('default')
  end

  it 'calculates exponential backoff for MutexLockError' do
    retry_block = described_class.sidekiq_retry_in_block
    expect(retry_block).to be_present

    exception = MutexLockError.new('Resource locked')
    expect(retry_block.call(0, exception)).to eq(1)
    expect(retry_block.call(1, exception)).to eq(2)
    expect(retry_block.call(2, exception)).to eq(4)
    expect(retry_block.call(3, exception)).to eq(8)
  end

  it 'returns nil backoff for non-MutexLockError exceptions' do
    retry_block = described_class.sidekiq_retry_in_block
    standard_error = StandardError.new('Random error')
    expect(retry_block.call(1, standard_error)).to be_nil
  end
end

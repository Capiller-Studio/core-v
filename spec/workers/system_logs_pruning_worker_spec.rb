# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemLogsPruningWorker, type: :worker do
  describe '#perform' do
    it 'deletes expired system logs in batches' do
      relation = double('expired_relation')
      batch = double('batch')
      allow(SystemLog).to receive(:expired).and_return(relation)
      allow(relation).to receive(:in_batches).with(of: 5000).and_return(batch)
      expect(batch).to receive(:delete_all)

      described_class.new.perform
    end

    it 'rescues errors and logs failure without raising' do
      allow(SystemLog).to receive(:expired).and_raise(StandardError.new('DB connection issue'))
      expect(Rails.logger).to receive(:error).with(/SystemLogsPruningWorker failed: DB connection issue/)

      expect { described_class.new.perform }.not_to raise_error
    end
  end
end

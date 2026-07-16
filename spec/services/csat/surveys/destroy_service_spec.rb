require 'rails_helper'

RSpec.describe Csat::Surveys::DestroyService do
  let(:account) { double('Account') }
  let(:survey) { double('Survey', account: account) }
  let(:service) { described_class.new(survey) }

  describe '#call' do
    before do
      allow(account).to receive(:with_shard).and_yield
      allow(ShardRecord).to receive(:transaction).and_yield
    end

    it 'destroys the survey' do
      expect(survey).to receive(:destroy!)
      service.call
    end
  end
end

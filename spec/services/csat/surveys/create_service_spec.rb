require 'rails_helper'

RSpec.describe Csat::Surveys::CreateService do
  let(:account) { double('Account') }
  let(:params) { { name: 'Support Feedback' } }
  let(:service) { described_class.new(account, params) }

  describe '#call' do
    let(:survey) { double('Survey') }

    before do
      allow(account).to receive(:with_shard).and_yield
      allow(ShardRecord).to receive(:transaction).and_yield
    end

    it 'creates a new survey and sets the account' do
      expect(Csat::Survey).to receive(:new).with(params).and_return(survey)
      expect(survey).to receive(:account=).with(account)
      expect(survey).to receive(:save!)

      expect(service.call).to eq(survey)
    end
  end
end

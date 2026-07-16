require 'rails_helper'

RSpec.describe Affiliates::Commissions::HoldingManager do
  let(:service) { described_class.new }

  describe '#call' do
    let(:profile1) { double('Profile', holding_days: 14) }
    let(:profile2) { double('Profile', holding_days: 30) }
    
    let(:commission1) { double('Commission', id: 1, profile: profile1, created_at: 15.days.ago, transaction_record_id: 'txn_1') }
    let(:commission2) { double('Commission', id: 2, profile: profile2, created_at: 15.days.ago, transaction_record_id: 'txn_2') }

    before do
      stub_const('Affiliate::Commission', double('CommissionClass'))
      allow(Affiliate::Commission).to receive_message_chain(:pending, :find_each).and_yield(commission1).and_yield(commission2)
    end

    it 'marks commissions as available if holding period has passed' do
      expect(commission1).to receive(:available!)
      expect(commission2).not_to receive(:available!)

      service.call
    end
  end
end

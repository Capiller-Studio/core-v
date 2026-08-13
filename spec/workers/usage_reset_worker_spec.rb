require 'rails_helper'

# rubocop:disable RSpec/AnyInstance
RSpec.describe UsageResetWorker, type: :worker do
  describe '#perform' do
    let(:plan) { create(:plan, features: { "monthly_ai_credits" => 100 }) }
    let(:account) { create(:account) }

    before { account.ai_wallet || Ai::Wallet.create!(account: account, balance: 0)
allow_any_instance_of(Account).to receive(:reset_monthly_counters!)
     }


    context 'with a subscription starting today' do
      before { create(:subscription, account: account, plan: plan, status: :active, current_period_start: Date.current) }

      it 'skips it because SubscriptionCreator/RenewalWorker handle it' do
        expect_any_instance_of(Account).not_to receive(:reset_monthly_counters!)
        described_class.new.perform
      end
    end

    context 'with an annual subscription on its monthly anniversary' do
      before { create(:subscription, account: account, plan: plan, status: :active, current_period_start: 1.month.ago, next_usage_reset_at: 1.hour.ago) }

      it 'resets counters and grants AI credits' do
        expect_any_instance_of(Account).to receive(:reset_monthly_counters!)
        
        expect {
          described_class.new.perform
        }.to change(Ai::CreditGrant, :count).by(1)
        
        grant = Ai::CreditGrant.last
        expect(grant.amount).to eq(100)
        expect(grant.description).to eq("billing.events.monthly_ai_grant")
        expect(grant.expires_at.to_date).to eq(1.month.from_now.to_date)
      end
    end

    context 'with an annual subscription NOT on its anniversary' do
      before { create(:subscription, account: account, plan: plan, status: :active, current_period_start: 15.days.ago, next_usage_reset_at: 15.days.from_now) }

      it 'skips it' do
        expect_any_instance_of(Account).not_to receive(:reset_monthly_counters!)
        expect {
          described_class.new.perform
        }.not_to change(Ai::CreditGrant, :count)
      end
    end
  end
end

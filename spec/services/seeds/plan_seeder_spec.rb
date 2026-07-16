require 'rails_helper'

RSpec.xdescribe Seeds::PlanSeeder do
  describe '.seed' do
    it 'creates plans for each supported currency' do
      expect {
        described_class.seed
      }.to change { Plan.count }.by(Plan::NAMES.count * Core::SUPPORTED_CURRENCIES.count)
       .and change { PlanTranslation.count }.by(Plan::NAMES.count * Core::SUPPORTED_CURRENCIES.count)

      # Check one specific plan
      plan = Plan.find_by(name: Plan::HYPERBOLIC, currency: 'USD')
      expect(plan).not_to be_nil
      expect(plan.base_price).to eq(19)
      expect(plan.annual_price).to eq(15)
      expect(plan.limits['users_max']).to eq(30)
      expect(plan.features['macros']).to eq(true)
      
      translation = plan.translations.find_by(locale: 'en')
      expect(translation).not_to be_nil
    end

    it 'is idempotent' do
      described_class.seed

      expect {
        described_class.seed
      }.to change { Plan.count }.by(0)
       .and change { PlanTranslation.count }.by(0)
    end
  end
end

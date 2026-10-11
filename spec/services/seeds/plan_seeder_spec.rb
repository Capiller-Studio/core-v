require 'rails_helper'

RSpec.describe Seeds::PlanSeeder do
  describe '.seed' do
    it 'creates plans for each supported currency' do
      expect {
        described_class.seed
      }.to change { Plan.count }.by(Plan::NAMES.count * Core::SUPPORTED_CURRENCIES.count)
       .and change { PlanTranslation.count }.by(Plan::NAMES.count * Core::SUPPORTED_CURRENCIES.count)

      # Check Hyperbolic plan
      plan = Plan.find_by(name: Plan::HYPERBOLIC, currency: 'USD')
      expect(plan).not_to be_nil
      expect(plan.base_price).to eq(19)
      expect(plan.annual_price).to eq(17)
      expect(plan.limits['users_max']).to eq(30)
      expect(plan.limits['channels']).to eq(15)
      expect(plan.limits['ai_agents']).to eq(3)
      expect(plan.limits['automations']).to eq(25)
      expect(plan.limits['assignment_policies']).to eq(5)
      expect(plan.limits['identity_sources']).to eq(0)
      expect(plan.limits['custom_fields']).to eq(20)
      expect(plan.features['macros']).to eq(true)
      expect(plan.features['monthly_ai_credits']).to eq(250)
      expect(plan.features.dig('channels', 'mobile_widget')).to eq(true)
      
      # Check Parabolic plan bounded channel limit and pricing
      parabolic = Plan.find_by(name: Plan::PARABOLIC, currency: 'USD')
      expect(parabolic.base_price).to eq(29)
      expect(parabolic.annual_price).to eq(26)
      expect(parabolic.limits['channels']).to eq(50)
      expect(parabolic.limits['ai_agents']).to eq(15)
      expect(parabolic.limits['assignment_policies']).to eq(25)
      expect(parabolic.limits['identity_sources']).to eq(10)
      expect(parabolic.limits['custom_fields']).to eq(100)
      expect(parabolic.limits['data_retention_months']).to eq(60)
      expect(parabolic.features['monthly_ai_credits']).to eq(500)
      expect(parabolic.features['sso']).to be(false)
      expect(parabolic.features['scim']).to be(false)

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

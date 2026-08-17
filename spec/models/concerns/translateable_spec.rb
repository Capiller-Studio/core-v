# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Translateable, type: :model do
  let(:account) { create(:account, locale: 'en') }
  let(:plan) { create(:plan, name: Plan::ANABOLIC, display_name: 'Anabolic Plan') }

  describe '#translates and translation resolution' do
    it 'sets and gets translated attributes per current I18n locale' do
      I18n.with_locale(:en) do
        plan.display_name = 'Professional Plan'
      end

      I18n.with_locale(:es) do
        plan.display_name = 'Plan Profesional'
      end

      plan.save!

      I18n.with_locale(:en) do
        expect(plan.display_name).to eq('Professional Plan')
      end

      I18n.with_locale(:es) do
        expect(plan.display_name).to eq('Plan Profesional')
      end
    end

    it 'falls back to default locale when translation is missing' do
      I18n.with_locale(:en) do
        plan.display_name = 'Enterprise Plan'
        plan.save!
      end

      I18n.with_locale(:fr) do
        expect(plan.display_name).to eq('Enterprise Plan')
      end
    end

    it 'checks whether record is translated to a specific locale' do
      I18n.with_locale(:es) do
        plan.display_name = 'Plan Espanol'
        plan.save!
      end

      expect(plan.translated_to?(:es)).to be(true)
      expect(plan.translated_to?(:de)).to be(false)
    end
  end
end

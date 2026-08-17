# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanTranslation, type: :model do
  let(:plan) { create(:plan) }

  describe 'Associations and Validations' do
    it { is_expected.to belong_to(:plan) }
    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:display_name) }

    it 'validates uniqueness of locale scoped to plan_id' do
      described_class.create!(plan: plan, locale: 'es', display_name: 'Plan Inicial')
      dup = described_class.new(plan: plan, locale: 'es', display_name: 'Otro Plan')

      expect(dup).not_to be_valid
      expect(dup.errors[:locale]).to include('has already been taken')
    end
  end
end

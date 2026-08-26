# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan, type: :model do
  describe "Associations" do
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_many(:subscriptions) }
    it { is_expected.to have_many(:translations) }
    it { is_expected.to have_many(:account_plans).dependent(:destroy) }
    it { is_expected.to have_many(:allowed_accounts).through(:account_plans).source(:account) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:currency) }
  end

  describe "Enums" do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, archived: 1) }
    it { is_expected.to define_enum_for(:visibility).with_values(public_plan: 0, private_plan: 1) }
  end
end

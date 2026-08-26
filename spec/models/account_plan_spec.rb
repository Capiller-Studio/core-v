# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountPlan, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:plan) }
  end
end

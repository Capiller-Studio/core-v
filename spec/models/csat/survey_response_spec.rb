require 'rails_helper'

RSpec.describe Csat::SurveyResponse, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:csat_survey).optional }
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:message).optional }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, submitted: 1) }
  end

end

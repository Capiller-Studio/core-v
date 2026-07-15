require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:from_currency) }
    it { is_expected.to validate_presence_of(:to_currency) }
    it { is_expected.to validate_presence_of(:rate) }
  end

end

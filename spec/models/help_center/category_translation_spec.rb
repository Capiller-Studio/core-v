require 'rails_helper'

RSpec.describe HelpCenter::CategoryTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:category) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:name) }
  end

end

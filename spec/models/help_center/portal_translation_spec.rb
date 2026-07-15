require 'rails_helper'

RSpec.describe HelpCenter::PortalTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:portal) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:locale) }
  end

end

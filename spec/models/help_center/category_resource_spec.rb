require 'rails_helper'

RSpec.describe HelpCenter::CategoryResource, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:resource) }
  end

end

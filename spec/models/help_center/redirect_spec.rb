require 'rails_helper'

RSpec.describe HelpCenter::Redirect, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:portal) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:source_path) }
    it { is_expected.to validate_presence_of(:target_path) }
  end

end

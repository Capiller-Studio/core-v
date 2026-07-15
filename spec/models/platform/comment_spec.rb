require 'rails_helper'

RSpec.describe Platform::Comment, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:commentable) }
    it { is_expected.to belong_to(:staff) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:content) }
  end

end

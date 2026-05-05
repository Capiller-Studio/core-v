require 'rails_helper'

RSpec.describe Label, type: :model do
  subject { build(:label) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end
end

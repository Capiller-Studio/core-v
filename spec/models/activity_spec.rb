require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:actor).optional }
    it { is_expected.to belong_to(:trackable) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:event_key) }
  end

end

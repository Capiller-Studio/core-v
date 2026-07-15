require 'rails_helper'

RSpec.describe Integration, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:webhook_deliveries) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:provider) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:provider).with_values(slack: 0, google_translate: 1, webhook: 2) }
  end

end

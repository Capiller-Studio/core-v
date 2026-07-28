require 'rails_helper'

RSpec.describe Webhook::Delivery, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:attempts) }
    it { is_expected.to belong_to(:resource) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:event_name) }
    it { is_expected.to validate_presence_of(:endpoint_url) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, successful: 1, failed: 2) }
  end

end

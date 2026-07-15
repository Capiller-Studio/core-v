require 'rails_helper'

RSpec.describe WebhookDeliveryAttempt, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:delivery) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:attempt_number) }
  end

end

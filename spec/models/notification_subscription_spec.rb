require 'rails_helper'

RSpec.describe NotificationSubscription, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:subscription_type).with_values(push: 0, fcm: 1) }
  end

end

require 'rails_helper'

RSpec.describe NotificationSetting, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

end

require 'rails_helper'

RSpec.describe InboxUser, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:user) }
  end

end

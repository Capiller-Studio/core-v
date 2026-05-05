require 'rails_helper'

RSpec.describe CannedResponse, type: :model do
  subject { build(:canned_response) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
  end

  describe 'Code Generation' do
    it 'generates a unique identifier with CR prefix' do
      cr = create(:canned_response)
      expect(cr.identifier).to start_with('CR')
    end
  end
end

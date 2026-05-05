require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'Associations' do
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:accounts).through(:account_users) }
    it { is_expected.to have_one(:affiliate_profile).dependent(:destroy) }
    it { is_expected.to belong_to(:address) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
    it { is_expected.to define_enum_for(:gender).with_values(male: 0, female: 1) }
  end

  describe 'Callbacks' do
    it 'configures display_name before save' do
      user = build(:user, first_name: 'John', middle_name: 'M.', last_name: 'Doe')
      user.save!
      expect(user.display_name).to eq('John M. Doe')
    end

    it 'generates a connection_token automatically' do
      user = create(:user)
      expect(user.connection_token).to be_present
    end
  end

  describe '#event_payload' do
    let(:user) { create(:user, first_name: 'Jane', last_name: 'Smith') }

    it 'returns the basic user data' do
      payload = user.event_payload
      expect(payload[:id]).to eq(user.id)
      expect(payload[:name]).to eq(user.name)
      expect(payload[:display_name]).to eq('Jane Smith')
    end
  end
end

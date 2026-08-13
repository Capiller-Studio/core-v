require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'Associations' do
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:accounts).through(:account_users) }
    it { is_expected.to have_many(:team_users).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:team_users) }
    it { is_expected.to have_one(:affiliate_profile).dependent(:destroy) }
    it { is_expected.to belong_to(:address) }
    
    it { is_expected.to have_many(:user_skills).dependent(:destroy) }
    it { is_expected.to have_many(:skills).through(:user_skills) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:destroy) }
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

    it 'includes avatar_url if avatar is attached' do
      user.avatar.attach(io: StringIO.new('dummy'), filename: 'avatar.png', content_type: 'image/png')
      payload = user.event_payload
      expect(payload[:avatar_url]).to be_present
    end
  end

  describe '#send_devise_notification' do
    it 'sends the devise notification in the background' do
      user = create(:user)
      expect {
        user.send_devise_notification(:reset_password_instructions, 'token')
      }.to have_enqueued_job
    end
  end
end

require 'rails_helper'

RSpec.describe Channel::Instagram, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_one(:primary_inbox) }
  end

  describe 'Validations' do
    subject { build(:channel_instagram) }

    it { is_expected.to validate_presence_of(:instagram_id) }
    it { is_expected.to validate_uniqueness_of(:instagram_id).case_insensitive }
    it { is_expected.to validate_presence_of(:access_token) }
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe 'Token Lifecycle' do
    let(:instagram) { build(:channel_instagram, expires_at: 30.days.from_now) }

    it '#token_expired? returns true if expired' do
      expect(instagram.token_expired?).to be false
      instagram.expires_at = 1.day.ago
      expect(instagram.token_expired?).to be true
    end

    it '#token_expiring_soon? returns true if expiring in less than 7 days' do
      expect(instagram.token_expiring_soon?).to be false
      instagram.expires_at = 5.days.from_now
      expect(instagram.token_expiring_soon?).to be true
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disconnected: 1) }
  end

end

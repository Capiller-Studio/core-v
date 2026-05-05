require 'rails_helper'

RSpec.describe Conversation, type: :model do
  subject { build(:conversation) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:campaign).optional }
    it { is_expected.to have_many(:conversation_members).dependent(:destroy) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:customers).through(:conversation_members) }
    it { is_expected.to have_many(:users).through(:conversation_members) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, closed: 1, snoozed: 2, resolved: 3) }
    it { is_expected.to define_enum_for(:priority).with_values(low: 0, medium: 1, high: 2, urgent: 3) }
    it { is_expected.to define_enum_for(:source).with_values(
      email: 0, facebook_message: 1, whatsapp: 2, instagram_direct_message: 3,
      api: 4, web_widget: 5, sms: 6, telegram: 7, help_center: 8
    ).with_suffix(:source) }
  end

  describe 'Callbacks' do
    it 'updates last_activity_at when status changes' do
      conversation = create(:conversation)
      Timecop.freeze(1.hour.from_now) do
        expect {
          conversation.update!(status: :closed)
        }.to change { conversation.last_activity_at }
      end
    end
  end

  describe '#update_last_activity' do
    it 'updates last_activity_at' do
      conversation = create(:conversation)
      expect {
        conversation.update_last_activity
      }.to change { conversation.last_activity_at }
    end
  end
end

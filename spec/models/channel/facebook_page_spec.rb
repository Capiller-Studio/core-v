require 'rails_helper'

RSpec.describe Channel::FacebookPage, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_one(:primary_inbox) }
  end

  describe 'Validations' do
    before do
      allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
      allow(Facebook::Messenger::Subscriptions).to receive(:unsubscribe).and_return(true)
    end

    subject { create(:channel_facebook_page) }
    
    it { is_expected.to validate_presence_of(:page_identifier) }
    it { is_expected.to validate_uniqueness_of(:page_identifier).scoped_to(:account_id).with_message("is already connected to this account") }
    it { is_expected.to validate_presence_of(:access_token) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disconnected: 1) }
  end

  describe 'Callbacks' do
    it 'subscribes and unsubscribes to webhooks' do
      page = build(:channel_facebook_page)
      expect(Facebook::Messenger::Subscriptions).to receive(:subscribe).with(access_token: page.access_token, subscribed_fields: Channel::FacebookPage::SUBSCRIBE_FIELDS)
      page.save!

      expect(Facebook::Messenger::Subscriptions).to receive(:unsubscribe).with(access_token: page.access_token)
      page.destroy!
    end
  end
end

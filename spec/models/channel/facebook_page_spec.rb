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

  describe '#refresh_page_token!' do
    let(:page) { build(:channel_facebook_page, page_identifier: 'page_123', user_access_token: 'user_tok_123') }
    let(:koala_client) { instance_double(Koala::Facebook::API) }

    before do
      allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
      allow(Facebook::Messenger::Subscriptions).to receive(:unsubscribe).and_return(true)
      allow(Koala::Facebook::API).to receive(:new).with('user_tok_123').and_return(koala_client)
    end

    it 'refreshes page access token from user accounts' do
      accounts = [
        { "id" => "other_page", "access_token" => "other_tok" },
        { "id" => "page_123", "access_token" => "new_page_token" }
      ]
      expect(koala_client).to receive(:get_connections).with("me", "accounts").and_return(accounts)
      expect(page).to receive(:update!).with(access_token: "new_page_token")
      expect(page).to receive(:reauthorized!)

      page.refresh_page_token!
    end

    it 'triggers authorization_error! when page is not found in user accounts' do
      expect(koala_client).to receive(:get_connections).with("me", "accounts").and_return([])
      expect(page).to receive(:authorization_error!)

      page.refresh_page_token!
    end

    it 'handles Koala::Facebook::AuthenticationError and triggers authorization_error!' do
      expect(koala_client).to receive(:get_connections).with("me", "accounts").and_raise(
        Koala::Facebook::AuthenticationError.new(401, 'User token expired')
      )
      expect(page).to receive(:authorization_error!)

      expect { page.refresh_page_token! }.not_to raise_error
    end

    it 'does nothing when user_access_token is blank' do
      page.user_access_token = nil
      expect(Koala::Facebook::API).not_to receive(:new)

      page.refresh_page_token!
    end
  end
end

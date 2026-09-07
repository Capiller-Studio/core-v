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
    let(:instagram) { build(:channel_instagram, instagram_id: 'ig_user_1', access_token: 'valid_token', expires_at: 30.days.from_now) }

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

    describe '#refresh_token!' do
      it 'successfully refreshes access token and calculates expires_at' do
        response = double('Response', success?: true, body: '{"access_token":"new_refreshed_token","expires_in":5184000}')
        expect(HTTParty).to receive(:get).with(
          "https://graph.instagram.com/refresh_access_token",
          query: {
            grant_type: "ig_refresh_token",
            access_token: 'valid_token'
          }
        ).and_return(response)

        expect(instagram).to receive(:update!).with(
          hash_including(
            access_token: "new_refreshed_token"
          )
        )
        expect(instagram).to receive(:reauthorized!)

        instagram.refresh_token!
      end

      it 'defaults expires_in to 60 days when expires_in is missing or zero' do
        response = double('Response', success?: true, body: '{"access_token":"new_refreshed_token","expires_in":0}')
        allow(HTTParty).to receive(:get).and_return(response)

        expect(instagram).to receive(:update!) do |attrs|
          expect(attrs[:access_token]).to eq("new_refreshed_token")
          expect(attrs[:expires_at]).to be > 59.days.from_now
        end
        expect(instagram).to receive(:reauthorized!)

        instagram.refresh_token!
      end

      it 'safely handles non-JSON / HTML error pages from Meta and triggers authorization_error!' do
        response = double('Response', success?: false, body: '<html><body>502 Bad Gateway</body></html>')
        allow(HTTParty).to receive(:get).and_return(response)

        expect(instagram).to receive(:authorization_error!)
        expect { instagram.refresh_token! }.not_to raise_error
      end

      it 'triggers authorization_error! when Meta returns error payload' do
        response = double('Response', success?: false, body: '{"error":{"message":"Invalid OAuth access token."}}')
        allow(HTTParty).to receive(:get).and_return(response)

        expect(instagram).to receive(:authorization_error!)
        instagram.refresh_token!
      end
    end

    describe '#unsubscribe_from_webhooks' do
      it 'calls Meta Graph API to unsubscribe on before_destroy' do
        expect(HTTParty).to receive(:delete).with(
          "https://graph.instagram.com/v26.0/ig_user_1/subscribed_apps",
          query: { access_token: 'valid_token' }
        )

        instagram.send(:unsubscribe_from_webhooks)
      end

      it 'does not call HTTParty if instagram_id is blank' do
        instagram.instagram_id = nil
        expect(HTTParty).not_to receive(:delete)

        instagram.send(:unsubscribe_from_webhooks)
      end
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disconnected: 1) }
  end
end

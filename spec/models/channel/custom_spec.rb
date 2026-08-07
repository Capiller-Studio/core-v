require 'rails_helper'

RSpec.describe Channel::Custom, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_one(:primary_inbox) }
    it { is_expected.to have_many(:webhook_deliveries) }
  end

  describe 'Validations' do
    subject { create(:channel_custom) }
    it { is_expected.to validate_presence_of(:identifier) }
    
    it 'generates a new identifier if it is already taken' do
      duplicate = build(:channel_custom, account: subject.account, identifier: subject.identifier)
      duplicate.valid?
      expect(duplicate.identifier).not_to eq(subject.identifier)
      expect(duplicate.identifier).to be_present
    end

    describe '#validate_webhook_url_security' do
      it 'allows valid https urls' do
        cc = build(:channel_custom, webhook_url: 'https://example.com/webhook')
        expect(cc).to be_valid
      end

      it 'rejects local hosts unless in dev/test' do
        # It's test environment so it should allow it
        cc = build(:channel_custom, webhook_url: 'http://localhost/webhook')
        expect(cc).to be_valid
      end

      it 'rejects invalid format' do
        cc = build(:channel_custom, webhook_url: 'not-a-url')
        expect(cc).not_to be_valid
        expect(cc.errors[:webhook_url]).to include('must be a valid URL format')
      end
    end
  end

  describe 'Callbacks' do
    it 'generates identifier on create' do
      cc = build(:channel_custom, name: 'My Custom App', identifier: nil)
      cc.valid?
      expect(cc.identifier).to eq('my-custom-app')
    end

    it 'generates secrets on create' do
      cc = build(:channel_custom, webhook_secret: nil, hmac_token: nil)
      cc.valid?
      expect(cc.webhook_secret).to be_present
      expect(cc.hmac_token).to be_present
    end
  end

  describe 'Instance Methods' do
    it '#webhook_endpoint returns correct url' do
      cc = create(:channel_custom)
      host = ENV.fetch("FRONTEND_URL", "https://deskbolic.app")
      expect(cc.webhook_endpoint).to eq("#{host}/webhooks/custom/#{cc.account_id}/#{cc.id}")
    end

    it '#routing_identifier returns identifier' do
      cc = create(:channel_custom)
      expect(cc.routing_identifier).to eq(cc.identifier)
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disconnected: 1) }
  end

end

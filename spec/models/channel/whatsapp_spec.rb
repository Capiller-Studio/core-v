require 'rails_helper'

RSpec.describe Channel::Whatsapp, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_one(:primary_inbox) }
  end

  describe 'Flags' do
    it { is_expected.to respond_to(:provider_embedded_signup) }
  end

  describe 'Validations' do
    subject { create(:channel_whatsapp) }
    
    it { is_expected.to validate_presence_of(:full_phone_number) }
    
    it 'validates uniqueness of full_phone_number' do
      duplicate = build(:channel_whatsapp, full_phone_number: "+1234567891")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:full_phone_number]).to include("is already connected")
    end
    it { is_expected.to validate_presence_of(:phone_number_id) }
    it { is_expected.to validate_presence_of(:business_account_id) }
    it { is_expected.to validate_presence_of(:api_key) }
  end

  describe 'Callbacks' do
    it 'generates webhook_secret' do
      wa = build(:channel_whatsapp, webhook_secret: nil)
      wa.valid?
      expect(wa.webhook_secret).to be_present
    end
  end

  describe 'Methods' do
    it '#api_headers returns correct auth hash' do
      wa = build(:channel_whatsapp, api_key: 'test_key')
      expect(wa.api_headers['Authorization']).to eq('Bearer test_key')
    end

    it '#phone_number_endpoint returns graph api url' do
      wa = build(:channel_whatsapp, phone_number_id: '1234')
      expect(wa.phone_number_endpoint).to eq("https://graph.facebook.com/v25.0/1234")
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disconnected: 1) }
    it { is_expected.to define_enum_for(:service).with_values(cloud_api: 0) }
  end

end

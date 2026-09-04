# frozen_string_literal: true

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

    it { is_expected.to validate_presence_of(:phone_number_id) }
    it { is_expected.to validate_presence_of(:business_account_id) }
    it { is_expected.to validate_presence_of(:api_key) }

    it 'validates uniqueness of phone_number_id' do
      existing = create(:channel_whatsapp)
      duplicate = build(:channel_whatsapp, phone_number_id: existing.phone_number_id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone_number_id]).to include('is already connected')
    end

    it 'validates uniqueness of full_phone_number when present' do
      phone = "+1555#{SecureRandom.hex(4)}"
      existing = create(:channel_whatsapp, full_phone_number: phone)
      duplicate = build(:channel_whatsapp, full_phone_number: existing.full_phone_number)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:full_phone_number]).to include('is already connected')
    end

    it 'allows multiple channels with nil full_phone_number (Display-Name-Only)' do
      ch1 = create(:channel_whatsapp, full_phone_number: nil)
      ch2 = build(:channel_whatsapp, full_phone_number: nil)
      expect(ch2).to be_valid
    end
  end

  describe 'Callbacks' do
    it 'generates webhook_secret' do
      wa = build(:channel_whatsapp, webhook_secret: nil)
      wa.valid?
      expect(wa.webhook_secret).to be_present
    end

    it 'calculates and sanitizes full_phone_number from phone_code and phone_number' do
      wa = build(:channel_whatsapp, phone_code: '+1', phone_number: '(555) 234-5678')
      wa.valid?
      expect(wa.full_phone_number).to eq('+15552345678')
    end

    it 'normalizes full_phone_number when provided directly with special characters' do
      wa = build(:channel_whatsapp, phone_code: nil, phone_number: nil, full_phone_number: '+1 (555) 987-6543')
      wa.valid?
      expect(wa.full_phone_number).to eq('+15559876543')
    end
  end

  describe 'Routing' do
    it 'uses phone_number_id as routing_identifier' do
      wa = build(:channel_whatsapp, phone_number_id: 'phone_12345')
      expect(wa.routing_identifier).to eq('phone_12345')
      expect(wa.routing_type).to eq('whatsapp')
    end
  end

  describe 'Methods' do
    it '#api_headers returns correct auth hash' do
      wa = build(:channel_whatsapp, api_key: 'test_key')
      expect(wa.api_headers['Authorization']).to eq('Bearer test_key')
    end

    it '#phone_number_endpoint returns graph api url' do
      wa = build(:channel_whatsapp, phone_number_id: '1234')
      expect(wa.phone_number_endpoint).to eq('https://graph.facebook.com/v26.0/1234')
    end

    it '#business_account_endpoint returns graph api url' do
      wa = build(:channel_whatsapp, business_account_id: 'waba_999')
      expect(wa.business_account_endpoint).to eq('https://graph.facebook.com/v26.0/waba_999')
    end

    it '#template_language defaults to en_US when not set' do
      wa = build(:channel_whatsapp, configurations: {})
      expect(wa.template_language).to eq('en_US')
    end

    it '#template_language returns configured value when present' do
      wa = build(:channel_whatsapp, configurations: { 'template_language' => 'pt_BR' })
      expect(wa.template_language).to eq('pt_BR')
    end

    it '#approved_templates returns message_templates jsonb array' do
      templates = [{ 'name' => 'ticket_resolved', 'status' => 'APPROVED' }]
      wa = build(:channel_whatsapp, message_templates: templates)
      expect(wa.approved_templates).to eq(templates)
    end

    it '#approved_templates returns empty array when message_templates is nil' do
      wa = build(:channel_whatsapp, message_templates: nil)
      expect(wa.approved_templates).to eq([])
    end

    it '#webhook_url builds valid URL with account and channel ID' do
      chan_id = SecureRandom.uuid
      acc_id = SecureRandom.uuid
      wa = build(:channel_whatsapp)
      wa.id = chan_id
      wa.account_id = acc_id
      expect(wa.webhook_url).to eq("https://deskbolic.app/webhooks/whatsapp/#{acc_id}/#{chan_id}")
    end
  end

  describe 'Webhooks Unsubscription' do
    let(:account) { create(:account) }

    it 'unsubscribes using channel access token on destroy' do
      wa = account.with_shard { create(:channel_whatsapp, account: account) }

      success_response = double('Response', success?: true)
      expect(HTTParty).to receive(:delete).with(
        "https://graph.facebook.com/v26.0/#{wa.business_account_id}/subscribed_apps",
        headers: wa.api_headers
      ).and_return(success_response)

      account.with_shard { wa.destroy }
    end

    it 'falls back to app access token when channel token fails' do
      wa = account.with_shard { create(:channel_whatsapp, account: account) }

      fail_response = double('Response', success?: false)
      expect(HTTParty).to receive(:delete).with(
        "https://graph.facebook.com/v26.0/#{wa.business_account_id}/subscribed_apps",
        headers: wa.api_headers
      ).and_return(fail_response)

      allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_id).and_return('wa_app')
      allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_secret).and_return('wa_secret')

      expect(HTTParty).to receive(:delete).with(
        "https://graph.facebook.com/v26.0/#{wa.business_account_id}/subscribed_apps",
        headers: {
          "Authorization" => "Bearer wa_app|wa_secret",
          "Content-Type" => "application/json"
        }
      ).and_return(double('AppResponse', success?: true))

      account.with_shard { wa.destroy }
    end

    it 'does not prevent record deletion if unsubscription raises an exception' do
      wa = account.with_shard { create(:channel_whatsapp, account: account) }

      expect(HTTParty).to receive(:delete).and_raise(StandardError.new("Meta network failure"))
      expect(Rails.logger).to receive(:warn).with(/WhatsApp unsubscribe_from_webhooks warning/)

      expect { account.with_shard { wa.destroy } }.not_to raise_error
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disconnected: 1) }
    it { is_expected.to define_enum_for(:service).with_values(cloud_api: 0) }
  end
end

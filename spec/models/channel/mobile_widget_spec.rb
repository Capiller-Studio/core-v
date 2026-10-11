# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::MobileWidget, type: :model do
  let(:account) { create(:account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:portal).class_name('HelpCenter::Portal').optional }
    it { is_expected.to belong_to(:pre_chat_form).class_name('Channel::ContactForm').optional }
    it { is_expected.to belong_to(:fallback_channel).optional }
    it { is_expected.to have_many(:inboxes).dependent(:destroy) }
    it { is_expected.to have_one(:primary_inbox).class_name('Inbox') }
    it { is_expected.to have_many(:customer_devices).through(:inboxes) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, suspended: 1) }
    it { is_expected.to define_enum_for(:apns_environment).with_values(sandbox: 0, production: 1).with_prefix(:apns) }
  end

  describe 'Flags' do
    it { is_expected.to respond_to(:anonymous_allowed) }
    it { is_expected.to respond_to(:secure_identity_enforced) }
    it { is_expected.to respond_to(:help_center_enabled) }
    it { is_expected.to respond_to(:pre_chat_form_enabled) }
    it { is_expected.to respond_to(:push_enabled) }
    it { is_expected.to respond_to(:custom_branding) }
    it { is_expected.to respond_to(:attachments_enabled) }
  end

  describe 'Validations' do
    subject { create(:channel_mobile_widget, account: account) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier) }
    it { is_expected.to validate_presence_of(:secret) }

    describe 'APNs key & team ID validations' do
      it 'validates apns_key_id length is exactly 10 characters when present' do
        widget = build(:channel_mobile_widget, account: account, apns_key_id: 'ABC123456')
        expect(widget).not_to be_valid
        expect(widget.errors[:apns_key_id]).to be_present

        widget.apns_key_id = 'ABC1234567'
        expect(widget).to be_valid
      end

      it 'validates apns_team_id length is exactly 10 characters when present' do
        widget = build(:channel_mobile_widget, account: account, apns_team_id: 'TEAM123')
        expect(widget).not_to be_valid
        expect(widget.errors[:apns_team_id]).to be_present

        widget.apns_team_id = 'TEAM123456'
        expect(widget).to be_valid
      end
    end

    describe 'Fallback channel account ownership' do
      let(:other_account) { create(:account) }
      let(:own_email_channel) { create(:channel_email, account: account) }
      let(:other_email_channel) { create(:channel_email, account: other_account) }

      it 'is valid when fallback channel belongs to the same account' do
        widget = build(:channel_mobile_widget, account: account, fallback_channel: own_email_channel)
        expect(widget).to be_valid
      end

      it 'is invalid when fallback channel belongs to a different account' do
        widget = build(:channel_mobile_widget, account: account, fallback_channel: other_email_channel)
        expect(widget).not_to be_valid
        expect(widget.errors[:fallback_channel]).to include('must belong to your account')
      end

      it 'is invalid when fallback channel id is provided but channel is not found' do
        widget = build(:channel_mobile_widget, account: account, fallback_channel_id: SecureRandom.uuid, fallback_channel_type: 'Channel::Email')
        expect(widget).not_to be_valid
        expect(widget.errors[:fallback_channel]).to include('must belong to your account')
      end
    end
  end

  describe 'Callbacks' do
    it 'auto-generates identifier with dbk_app_ prefix and secret on create' do
      widget = build(:channel_mobile_widget, account: account, identifier: nil, secret: nil)
      widget.valid?
      expect(widget.identifier).to start_with('dbk_app_')
      expect(widget.secret).to be_present
    end

    it 'extracts fcm_project_id from fcm_service_account JSON' do
      service_account = {
        type: 'service_account',
        project_id: 'my-firebase-app-123',
        client_email: 'firebase-adminsdk@my-firebase-app-123.iam.gserviceaccount.com'
      }.to_json

      widget = create(:channel_mobile_widget, account: account, fcm_service_account: service_account)
      expect(widget.fcm_project_id).to eq('my-firebase-app-123')
    end

    it 'handles malformed fcm_service_account gracefully' do
      widget = create(:channel_mobile_widget, account: account, fcm_service_account: 'not-valid-json')
      expect(widget.fcm_project_id).to be_nil
    end
  end

  describe 'Instance Methods' do
    let(:widget) { create(:channel_mobile_widget, account: account) }

    describe '#apns_configured?' do
      it 'returns false when APNs credentials are incomplete' do
        expect(widget.apns_configured?).to be false
      end

      it 'returns true when all 4 APNs keys are present' do
        widget.update!(
          apns_key: '-----BEGIN PRIVATE KEY-----...',
          apns_key_id: 'ABC1234567',
          apns_team_id: 'TEAM123456',
          ios_bundle_id: 'com.example.mobileapp'
        )
        expect(widget.apns_configured?).to be true
      end
    end

    describe '#fcm_configured?' do
      it 'returns false when FCM credentials are not configured' do
        expect(widget.fcm_configured?).to be false
      end

      it 'returns true when fcm_service_account and project_id are present' do
        widget.update!(
          fcm_service_account: { project_id: 'test-app' }.to_json
        )
        expect(widget.fcm_configured?).to be true
      end
    end

    describe '#regenerate_secret!' do
      it 'rotates secret and updates secret_rotated_at timestamp' do
        old_secret = widget.secret
        widget.regenerate_secret!
        widget.reload

        expect(widget.secret).not_to eq(old_secret)
        expect(widget.data['secret_rotated_at']).to be_present
      end
    end

    describe 'routing identifiers' do
      it 'returns correct routing identifier and type' do
        expect(widget.routing_identifier).to eq(widget.identifier)
        expect(widget.routing_type).to eq('mobile_widget')
        expect(widget.hmac_token).to eq(widget.secret)
      end
    end
  end
end

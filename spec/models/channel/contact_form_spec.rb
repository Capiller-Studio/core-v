require 'rails_helper'

RSpec.describe Channel::ContactForm, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    # it { is_expected.to have_many(:fields).class_name('Channel::ContactFormField').dependent(:destroy) }
    it { is_expected.to have_many(:portals).class_name('HelpCenter::Portal').dependent(:nullify) }
    it { is_expected.to belong_to(:outbound_channel).optional }
    it { is_expected.to have_many(:inboxes).dependent(:destroy) }
    it { is_expected.to have_one(:primary_inbox).class_name('Inbox') }
    it { is_expected.to have_many(:custom_field_resources).class_name('CustomFieldResource').dependent(:destroy) }
    it { is_expected.to have_many(:custom_fields).through(:custom_field_resources) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
  end

  describe 'Flags' do
    it { is_expected.to respond_to(:require_login) }
    it { is_expected.to respond_to(:allow_attachments) }
    it { is_expected.to respond_to(:send_confirmation_email) }
    it { is_expected.to respond_to(:spam_protection_enabled) }
  end

  describe 'Validations' do
    subject { create(:channel_contact_form) }

    it { is_expected.to validate_presence_of(:secret) }
    it { is_expected.to validate_uniqueness_of(:secret) }
    
    it { is_expected.to validate_length_of(:submit_redirect_url).is_at_most(255) }
    it { is_expected.to validate_inclusion_of(:outbound_channel_type).in_array(['Channel::Email']).allow_blank }

    describe '#validate_submit_redirect_url' do
      it 'allows valid https urls' do
        cf = build(:channel_contact_form, submit_redirect_url: 'https://example.com/thank-you')
        expect(cf).to be_valid
      end

      it 'rejects local hosts' do
        cf = build(:channel_contact_form, submit_redirect_url: 'http://localhost/thank-you')
        expect(cf).not_to be_valid
        expect(cf.errors[:submit_redirect_url]).to include('cannot be a local or internal address')
      end

      it 'rejects private ips' do
        cf = build(:channel_contact_form, submit_redirect_url: 'http://192.168.1.1/thanks')
        expect(cf).not_to be_valid
        expect(cf.errors[:submit_redirect_url]).to include('cannot be a private IP address')
      end

      it 'rejects invalid url format' do
        cf = build(:channel_contact_form, submit_redirect_url: 'not-a-url')
        expect(cf).not_to be_valid
        expect(cf.errors[:submit_redirect_url]).to include('must be a valid HTTP or HTTPS URL')
      end
    end

    describe '#validate_outbound_channel_ownership' do
      let(:account) { create(:account) }
      let(:other_account) { create(:account) }
      let(:email_channel) { create(:channel_email, account: other_account) }

      it 'validates outbound_channel belongs to the same account' do
        cf = build(:channel_contact_form, account: account, outbound_channel: email_channel)
        expect(cf).not_to be_valid
        expect(cf.errors[:outbound_channel]).to include('must belong to your account')
      end

      it 'is valid when outbound_channel belongs to the same account' do
        valid_email_channel = create(:channel_email, account: account)
        cf = build(:channel_contact_form, account: account, outbound_channel: valid_email_channel)
        expect(cf).to be_valid
      end
    end
  end

  describe 'Callbacks' do
    it 'ensures secret before validation on create' do
      cf = build(:channel_contact_form, secret: nil)
      cf.valid?
      expect(cf.secret).to be_present
    end
  end

  describe 'Instance Methods' do
    describe '#hmac_token' do
      it 'returns the secret' do
        cf = create(:channel_contact_form)
        expect(cf.hmac_token).to eq(cf.secret)
      end
    end

    describe '#supported_formatting' do
      it 'returns an array of supported formats' do
        cf = build(:channel_contact_form)
        expect(cf.supported_formatting).to include(:bold, :italic, :link, :image, :file)
      end
    end
  end
end

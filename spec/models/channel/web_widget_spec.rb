require 'rails_helper'

RSpec.describe Channel::WebWidget, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:portal).class_name('HelpCenter::Portal').optional }
    it { is_expected.to belong_to(:pre_chat_form).class_name('Channel::ContactForm').optional }
    it { is_expected.to belong_to(:fallback_channel).optional }
    it { is_expected.to have_many(:inboxes).dependent(:destroy) }
    it { is_expected.to have_one(:primary_inbox).class_name('Inbox') }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
  end

  describe 'Flags' do
    it { is_expected.to respond_to(:anonymous_allowed) }
    it { is_expected.to respond_to(:help_center_enabled) }
    it { is_expected.to respond_to(:pre_chat_form_enabled) }
    it { is_expected.to respond_to(:secure_identity_enforced) }
    it { is_expected.to respond_to(:custom_branding) }
  end

  describe 'Validations' do
    subject { create(:channel_web_widget) }

    it { is_expected.to validate_presence_of(:secret) }
    it { is_expected.to validate_uniqueness_of(:secret) }
    
    it { is_expected.to allow_value('', nil).for(:website_url) }
    it { is_expected.not_to allow_value('invalid-url').for(:website_url) }
  end

  describe 'Callbacks' do
    it 'ensures secret is present' do
      widget = build(:channel_web_widget, secret: nil)
      widget.valid?
      expect(widget.secret).to be_present
    end
  end
end

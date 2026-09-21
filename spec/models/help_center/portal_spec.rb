require 'rails_helper'

RSpec.describe HelpCenter::Portal, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to belong_to(:contact_form_channel).optional }
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to belong_to(:domain) }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_one(:favicon_attachment) }
    it { is_expected.to have_one(:favicon_blob) }
    it { is_expected.to have_one(:hero_image_attachment) }
    it { is_expected.to have_one(:hero_image_blob) }
    it { is_expected.to have_one(:logo_attachment) }
    it { is_expected.to have_one(:logo_blob) }
    it { is_expected.to have_many(:redirects) }
    it { is_expected.to have_one(:social_share_image_attachment) }
    it { is_expected.to have_one(:social_share_image_blob) }
    it { is_expected.to have_many(:translations) }
    it { is_expected.to have_one(:web_widget_channel) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
  end

  describe 'Flags' do
    let(:portal) { described_class.new }

    it 'can set and get show_contact_form flag' do
      portal.show_contact_form = true
      expect(portal.show_contact_form?).to be true
    end

    it 'can set and get show_customer_portal flag' do
      portal.show_customer_portal = true
      expect(portal.show_customer_portal?).to be true
    end

    it 'can set and get show_web_widget flag' do
      portal.show_web_widget = true
      expect(portal.show_web_widget?).to be true
    end

    it 'can set and get indexing_enabled flag' do
      portal.indexing_enabled = true
      expect(portal.indexing_enabled?).to be true
    end

    it 'can set and get ai_training_enabled flag' do
      portal.ai_training_enabled = true
      expect(portal.ai_training_enabled?).to be true
    end
  end

  describe '#description' do
    it 'returns the hero_subtitle' do
      portal = described_class.new(hero_subtitle: 'Welcome to our support center')
      expect(portal.description).to eq('Welcome to our support center')
    end
  end

  describe '#contact_form_enabled?' do
    let(:portal) { described_class.new }
    let(:contact_form) { build_stubbed(:channel_contact_form) }

    it 'returns true when show_contact_form is true and contact_form_channel is present' do
      portal.show_contact_form = true
      portal.contact_form_channel = contact_form
      expect(portal.contact_form_enabled?).to be true
    end

    it 'returns false when show_contact_form is false even if contact_form_channel is present' do
      portal.show_contact_form = false
      portal.contact_form_channel = contact_form
      expect(portal.contact_form_enabled?).to be false
    end

    it 'returns false when show_contact_form is true but contact_form_channel is missing' do
      portal.show_contact_form = true
      portal.contact_form_channel = nil
      expect(portal.contact_form_enabled?).to be false
    end
  end
end

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

end

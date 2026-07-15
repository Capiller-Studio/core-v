require 'rails_helper'

RSpec.describe HelpCenter::Article, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:activities) }
    it { is_expected.to belong_to(:author).optional }
    it { is_expected.to have_one(:banner_image_attachment) }
    it { is_expected.to have_one(:banner_image_blob) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to have_many(:category_resources) }
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_many(:images_attachments) }
    it { is_expected.to have_many(:images_blobs) }
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to belong_to(:primary_category).optional }
    it { is_expected.to have_many(:related_articles) }
    it { is_expected.to have_many(:related_resources) }
    it { is_expected.to have_many(:translations) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1, archived: 2) }
    it { is_expected.to define_enum_for(:article_type).with_values(standard: 0, external_link: 1, api_endpoint: 2) }
    it { is_expected.to define_enum_for(:visibility).with_values(everyone: 0, unlisted: 1, internal: 2) }
  end

end

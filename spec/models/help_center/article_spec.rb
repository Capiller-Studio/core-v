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

  describe 'Callbacks' do
    describe '#calculate_estimated_read_time' do
      let(:article) { described_class.new(content: 'word ' * 400) }

      before do
        article.singleton_class.class_eval { attr_accessor :stats }
        article.stats = {}
      end

      it 'calculates and sets estimated_read_time in stats if blank' do
        article.send(:calculate_estimated_read_time)
        expect(article.stats['estimated_read_time']).to eq(2)
      end

      it 'does not override manually set estimated_read_time' do
        article.stats['estimated_read_time'] = 10
        article.send(:calculate_estimated_read_time)
        expect(article.stats['estimated_read_time']).to eq(10)
      end
    end
  end

end

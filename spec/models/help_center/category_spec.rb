require 'rails_helper'

RSpec.describe HelpCenter::Category, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:category_resources) }
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_one(:image_attachment) }
    it { is_expected.to have_one(:image_blob) }
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to have_many(:translations) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
    it { is_expected.to define_enum_for(:visibility).with_values(everyone: 0, unlisted: 1, internal: 2) }
  end

  describe '#update_stats!' do
    let(:category) { described_class.new }
    let(:published_articles) { double('articles') }

    before do
      category.singleton_class.class_eval do
        attr_accessor :published_articles_count, :views_count, :stats
      end
      category.stats = {}
      
      articles_mock = double('articles_relation')
      allow(category).to receive(:articles).and_return(articles_mock)
      allow(articles_mock).to receive(:published).and_return(articles_mock)
      allow(articles_mock).to receive(:where).and_return(published_articles)
      allow(published_articles).to receive(:count).and_return(5)
      allow(published_articles).to receive(:sum).with(:views_count).and_return(100)
      allow(published_articles).to receive(:average).and_return(2.5)
      allow(category).to receive(:save!)
    end

    it 'updates published_articles_count, views_count, and average_read_time' do
      category.update_stats!
      
      expect(category.published_articles_count).to eq(5)
      expect(category.views_count).to eq(100)
      expect(category.stats['average_read_time']).to eq(2)
      expect(category).to have_received(:save!).with(validate: false)
    end
  end

end

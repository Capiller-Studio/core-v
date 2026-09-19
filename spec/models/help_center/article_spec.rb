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

    describe '#queue_vector_embedding' do
      let(:portal) { HelpCenter::Portal.new(id: SecureRandom.uuid) }
      let(:article) { described_class.new(id: SecureRandom.uuid, account_id: SecureRandom.uuid, portal: portal, status: :published, article_type: :standard) }

      before do
        allow(Ai::VectorEmbedderWorker).to receive(:perform_async)
      end

      it 'queues embedding if portal has ai_training_enabled' do
        allow(portal).to receive(:ai_training_enabled?).and_return(true)
        article.send(:queue_vector_embedding)
        expect(Ai::VectorEmbedderWorker).to have_received(:perform_async).with(article.account_id, article.id)
      end

      it 'does not queue if ai_training is disabled' do
        allow(portal).to receive(:ai_training_enabled?).and_return(false)
        article.send(:queue_vector_embedding)
        expect(Ai::VectorEmbedderWorker).not_to have_received(:perform_async)
      end

      it 'does not queue if article is not published' do
        article.status = :draft
        allow(portal).to receive(:ai_training_enabled?).and_return(true)
        article.send(:queue_vector_embedding)
        expect(Ai::VectorEmbedderWorker).not_to have_received(:perform_async)
      end

      it 'does not queue if article is not standard' do
        article.article_type = :external_link
        allow(portal).to receive(:ai_training_enabled?).and_return(true)
        article.send(:queue_vector_embedding)
        expect(Ai::VectorEmbedderWorker).not_to have_received(:perform_async)
      end
    end

    describe '#update_category_stats' do
      let(:category) { HelpCenter::Category.new }
      let(:article) { described_class.new }

      it 'calls update_stats! on all associated categories' do
        allow(article).to receive(:categories).and_return([category])
        allow(category).to receive(:update_stats!)
        
        article.send(:update_category_stats)
        expect(category).to have_received(:update_stats!)
      end
    end
  end

  describe '#search_data' do
    let(:article) { described_class.new(id: SecureRandom.uuid, account_id: SecureRandom.uuid, portal_id: SecureRandom.uuid, status: :published, visibility: :everyone, views_count: 5) }
    let(:embedding) { Array.new(1536) { 0.05 } }
    let(:translation_en) { HelpCenter::ArticleTranslation.new(locale: 'en', title: 'Test', slug: 'test', content: 'content', search_excerpt: 'excerpt', content_embedding: embedding) }
    let(:translation_es) { HelpCenter::ArticleTranslation.new(locale: 'es', title: 'Prueba', slug: 'prueba', content: 'contenido', search_excerpt: 'extracto', content_embedding: nil) }

    it 'returns the expected payload structure decoupling translations and embeddings' do
      allow(article).to receive(:translations).and_return([translation_en, translation_es])

      data = article.search_data
      expect(data[:status]).to eq('published')
      expect(data[:views_count]).to eq(5)
      expect(data[:translations].size).to eq(2)
      expect(data[:translations].first[:title]).to eq('Test')
      expect(data[:translations].first[:content]).to eq('content')
      expect(data[:translations].first).not_to have_key(:content_embedding)

      expect(data[:embeddings].size).to eq(1)
      expect(data[:embeddings].first[:locale]).to eq('en')
      expect(data[:embeddings].first[:content_embedding]).to eq(embedding)
    end
  end

end

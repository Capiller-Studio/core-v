# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::VectorEmbedderWorker, type: :worker do
  let(:account) { create(:account) }
  let(:article) { create(:help_center_article, account: account) }
  let(:translation) { article.translations.first }
  let(:mock_openai_client) { double('OpenAI::Client') }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_openai_client)
    allow(article).to receive(:reindex)
    allow(HelpCenter::Article).to receive(:find_by).with(id: article.id).and_return(article)
    translation.update_columns(ai_training_synced: false)
  end

  describe '#perform' do
    it 'generates vector embeddings for unsynced translations and deducts AI credits' do
      expect(Ai::CreditManager).to receive(:call).with(
        account: account,
        action_type: 'article_embedding',
        model_used: Ai::Client::MODELS[:embedding],
        cost: 1
      )

      embedding_vector = [0.1, 0.2, 0.3]
      expect(mock_openai_client).to receive(:embeddings).with(
        hash_including(
          parameters: hash_including(
            model: Ai::Client::MODELS[:embedding],
            input: kind_of(String)
          )
        )
      ).and_return({ 'data' => [{ 'embedding' => embedding_vector }] })

      expect(article).to receive(:reindex)

      described_class.new.perform(account.id, article.id)

      translation.reload
      expect(translation.content_embedding).to eq(embedding_vector)
      expect(translation.ai_training_synced).to be(true)
    end

    it 'refunds AI credit if embedding response is empty' do
      allow(Ai::CreditManager).to receive(:call)
      allow(mock_openai_client).to receive(:embeddings).and_return({ 'data' => [] })

      expect(Ai::CreditManager).to receive(:refund!).with(
        account: account,
        amount: 1,
        action_type: 'article_embedding'
      )

      described_class.new.perform(account.id, article.id)
    end

    it 'refunds AI credit and raises error if OpenAI API raises an error' do
      allow(Ai::CreditManager).to receive(:call)
      allow(mock_openai_client).to receive(:embeddings).and_raise(StandardError.new('API Rate Limit'))

      expect(Ai::CreditManager).to receive(:refund!).with(
        account: account,
        amount: 1,
        action_type: 'article_embedding'
      )
      expect(Rails.logger).to receive(:error).with(/VectorEmbedderWorker Failed: API Rate Limit/)

      expect {
        described_class.new.perform(account.id, article.id)
      }.to raise_error(StandardError, 'API Rate Limit')
    end

    it 'returns early if article is not found' do
      allow(HelpCenter::Article).to receive(:find_by).with(id: 'non-existent').and_return(nil)
      expect(Ai::CreditManager).not_to receive(:call)

      described_class.new.perform(account.id, 'non-existent')
    end
  end
end

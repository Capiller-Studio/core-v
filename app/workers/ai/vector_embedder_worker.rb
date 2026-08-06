# frozen_string_literal: true

module Ai
  class VectorEmbedderWorker
    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: "low"

    def perform(account_id, article_id)
      account = Account.find(account_id)
      
      account.with_shard do
        article = HelpCenter::Article.find_by(id: article_id)
        return unless article

        # Generate embeddings for each unsynced translation
        article.translations.where(ai_training_synced: false).find_each do |translation|
          text_to_embed = extract_text_for_embedding(translation)
          next if text_to_embed.blank?

          # Deduct 1 credit per embedding
          Ai::CreditManager.call(
            account: account,
            action_type: "article_embedding",
            model_used: Ai::Client::MODELS[:embedding],
            cost: 1
          )

          begin
            client = ::OpenAI::Client.new
            response = client.embeddings(
              parameters: {
                model: Ai::Client::MODELS[:embedding], # 1536 dims
                input: text_to_embed
              }
            )

            embedding = response.dig("data", 0, "embedding")
            
            if embedding
              translation.transaction do
                translation.update!(content_embedding: embedding, ai_training_synced: true)
              end
            else
              # If response was empty, refund the credit
              Ai::CreditManager.refund!(account: account, amount: 1, description: "Refund: OpenAI API returned empty embedding")
            end
          rescue => e
            # Refund the credit if API fails
            Ai::CreditManager.refund!(account: account, amount: 1, description: "Refund: OpenAI API failed")
            raise e
          end
        end

        # Re-index the article in Searchkick to sync the new vectors to Elasticsearch
        article.reindex
      end
    rescue => e
      Rails.logger.error("VectorEmbedderWorker Failed: #{e.message}")
      raise e
    end

    private

    def extract_text_for_embedding(translation)
      # We want to embed the title and the plain text content
      title = translation.title || ""
      
      # Strip HTML tags from ActionText or rich text content
      plain_content = ActionView::Base.full_sanitizer.sanitize(translation.content.to_s) || ""
      
      "#{title}\n\n#{plain_content}".strip
    end
  end
end

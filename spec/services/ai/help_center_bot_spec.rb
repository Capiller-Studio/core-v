# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::HelpCenterBot do
  let(:account) { create(:account) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:ai_agent) { create(:ai_agent, account: account, portal: portal, confidence_threshold: 0.7) }
  let(:inbox) { create(:inbox, account: account, ai_agent: ai_agent) }
  let(:openai_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    allow(Ai::Client).to receive(:call).and_return('Here is how to reset your password.')
  end

  describe '#call' do
    it 'returns fallback message when embedding fails' do
      expect(openai_client).to receive(:embeddings).and_return({ 'data' => [] })

      result = described_class.call(
        account: account,
        portal: portal,
        inbox: inbox,
        query: 'What is your refund policy?'
      )

      expect(result).to eq('Sorry, I am unable to answer this question. Connecting you to a human agent...')
    end

    it 'performs RAG search and generates AI response when articles match' do
      fake_embedding = [0.1, 0.2, 0.3]
      expect(openai_client).to receive(:embeddings).and_return({
        'data' => [{ 'embedding' => fake_embedding }]
      })

      article = create(:help_center_article, account: account, portal: portal, title: 'Password Reset', content: 'Click forgot password')
      search_double = double(
        'SearchkickResults',
        response: {
          'hits' => {
            'hits' => [
              { '_id' => article.id.to_s, '_score' => 0.95 }
            ]
          }
        },
        empty?: false
      )
      allow(search_double).to receive(:select).and_yield(article).and_return([article])
      allow(HelpCenter::Article).to receive(:search).and_return(search_double)

      result = described_class.call(
        account: account,
        portal: portal,
        inbox: inbox,
        query: 'How to reset password?'
      )

      expect(result).to eq('Here is how to reset your password.')
      expect(Ai::Client).to have_received(:call).with(
        hash_including(
          account: account,
          action_type: 'ai_agent_reply',
          model: :base
        )
      )
    end
  end
end

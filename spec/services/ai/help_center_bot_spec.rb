# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::HelpCenterBot do
  let(:account) { create(:account) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:ai_agent) { create(:ai_agent, account: account, portal: portal, confidence_threshold: 0.7) }
  let(:inbox) { create(:inbox, account: account, ai_agent: ai_agent) }
  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:empty_search_results) do
    double('SearchkickResults', response: { 'hits' => { 'hits' => [] } }, empty?: true, select: [])
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    allow(openai_client).to receive(:embeddings).and_return({
      'data' => [{ 'embedding' => [0.1, 0.2, 0.3] }]
    })
    allow(HelpCenter::Article).to receive(:search).and_return(empty_search_results)
    allow(Ai::Client).to receive(:call).and_return('Here is how to reset your password.')
  end

  describe '#call' do
    context 'when query is empty or media-only' do
      it 'returns handoff response for media review' do
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: '   '
        )

        expect(result.handoff?).to be true
        expect(result.intent).to eq(:media_attachment)
        expect(result.content).to include('review your attachment')
      end
    end

    context 'when query explicitly requests human support (Tier 1 fast dictionary)' do
      it 'immediately returns handoff in English without calling OpenAI' do
        expect(openai_client).not_to receive(:embeddings)
        expect(Ai::Client).not_to receive(:call)

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Can I please speak to a human agent?'
        )

        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
        expect(result.content).to eq("I'm connecting you with a human agent now. Someone from our team will be with you shortly.")
      end

      it 'immediately returns handoff in Spanish' do
        expect(openai_client).not_to receive(:embeddings)
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Quiero hablar con un agente humano por favor'
        )
        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
      end

      it 'immediately returns handoff in Arabic' do
        expect(openai_client).not_to receive(:embeddings)
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'أريد التحدث مع موظف خدمة العملاء'
        )
        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
      end

      it 'immediately returns handoff in German' do
        expect(openai_client).not_to receive(:embeddings)
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Ich möchte bitte mit einem Mitarbeiter sprechen'
        )
        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
      end

      it 'immediately returns handoff in French' do
        expect(openai_client).not_to receive(:embeddings)
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Je voudrais parler à un conseiller'
        )
        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
      end

      it 'immediately returns handoff in Korean' do
        expect(openai_client).not_to receive(:embeddings)
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: '상담원 연결 부탁드립니다'
        )
        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
      end

      it 'immediately returns handoff in Portuguese' do
        expect(openai_client).not_to receive(:embeddings)
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Por favor quero falar com um atendente humano'
        )
        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
      end
    end

    context 'when query is greeting or small talk' do
      it 'handles pure English greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('Hello! How can I assist you today?')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Hi'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
        expect(result.content).to eq('Hello! How can I assist you today?')
      end

      it 'handles Spanish greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('¡Hola Carlos! ¿En qué puedo ayudarte?')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Hola, soy Carlos'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
        expect(Ai::Client).to have_received(:call).with(
          hash_including(system_prompt: a_string_including('Carlos'))
        )
      end

      it 'handles Arabic greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('أهلاً أحمد! كيف يمكنني مساعدتك؟')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'مرحبا اسمي أحمد'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
      end

      it 'handles French greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('Bonjour Pierre! Comment puis-je vous aider?')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: "Bonjour, je m'appelle Pierre"
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
      end

      it 'handles German greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('Hallo Hans! Wie kann ich Ihnen helfen?')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Hallo, mein Name ist Hans'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
      end

      it 'handles Korean greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('안녕하세요! 무엇을 도와드릴까요?')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: '안녕하세요'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
      end

      it 'handles Portuguese greeting without handing off' do
        allow(Ai::Client).to receive(:call).and_return('Olá Lucas! Como posso ajudar hoje?')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Olá, meu nome é Lucas'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
      end

      it 'handles multi-message small talk burst without handing off' do
        allow(Ai::Client).to receive(:call).and_return('Hello Ahsan! How can I help you today?')

        burst_query = "Hi\nMy name is Ahsan\nI need help with something"
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: burst_query
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
        expect(Ai::Client).to have_received(:call).with(
          hash_including(
            action_type: 'ai_agent_reply',
            system_prompt: a_string_including('Ahsan')
          )
        )
      end

      it 'falls back to localized greeting if LLM fails, without handoff' do
        allow(Ai::Client).to receive(:call).and_raise(StandardError.new('API timeout'))

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Hello there'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:greeting)
        expect(result.content).to eq('Hello! How can I help you today?')
      end
    end

    context 'when query contains knowledge question' do
      it 'returns fallback message when embedding fails' do
        expect(openai_client).to receive(:embeddings).and_return({ 'data' => [] })

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'What is your refund policy?'
        )

        expect(result.handoff?).to be true
        expect(result.to_s).to eq('Sorry, I am unable to answer this question. Connecting you to a human agent...')
      end

      it 'performs RAG search and generates AI response when articles match' do
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

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:rag_answer)
        expect(result).to eq('Here is how to reset your password.')
        expect(Ai::Client).to have_received(:call).with(
          hash_including(
            account: account,
            action_type: 'ai_agent_reply',
            model: :base
          )
        )
      end

      it 'handles combined greeting burst and knowledge question in a single turn' do
        article = create(:help_center_article, account: account, portal: portal, title: 'Password Reset', content: 'Click forgot password')
        search_double = double(
          'SearchkickResults',
          response: {
            'hits' => {
              'hits' => [
                { '_id' => article.id.to_s, '_score' => 0.92 }
              ]
            }
          },
          empty?: false
        )
        allow(search_double).to receive(:select).and_yield(article).and_return([article])
        allow(HelpCenter::Article).to receive(:search).and_return(search_double)
        allow(Ai::Client).to receive(:call).and_return('Hello Ahsan! To reset your password, visit the login page. [Read Article](https://helpbolic.com/en/articles/reset)')

        burst_with_question = "Hi\nMy name is Ahsan\nI need help with something\nHow do I reset my password?"
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: burst_with_question
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:rag_answer)
        expect(result.content).to include('Hello Ahsan!')
        expect(Ai::Client).to have_received(:call).with(
          hash_including(
            system_prompt: a_string_including('Ahsan')
          )
        )
      end

      it 'selects matching locale translation for RAG context when available' do
        article = create(:help_center_article, account: account, portal: portal, title: 'English Title', content: 'English Content')
        article.translations.create!(locale: 'es', title: 'Título en Español', content: 'Contenido en Español', slug: 'titulo-espanol')

        search_double = double(
          'SearchkickResults',
          response: {
            'hits' => {
              'hits' => [{ '_id' => article.id.to_s, '_score' => 0.95 }]
            }
          },
          empty?: false
        )
        allow(search_double).to receive(:select).and_yield(article).and_return([article])
        allow(HelpCenter::Article).to receive(:search).and_return(search_double)

        I18n.with_locale(:es) do
          described_class.call(
            account: account,
            portal: portal,
            inbox: inbox,
            query: '¿Cómo restablecer contraseña?'
          )
        end

        expect(Ai::Client).to have_received(:call).with(
          hash_including(
            system_prompt: a_string_including('Título en Español', 'Contenido en Español')
          )
        )
      end

      it 'asks for clarification when short vague query matches no articles in English' do
        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'invoice'
        )

        expect(result.handoff?).to be false
        expect(result.intent).to eq(:clarification)
        expect(result.content).to include("Could you please provide a bit more detail about your request regarding 'invoice'?")
      end

      it 'asks for clarification in Spanish for Spanish locale' do
        I18n.with_locale(:es) do
          result = described_class.call(
            account: account,
            portal: portal,
            inbox: inbox,
            query: 'factura'
          )

          expect(result.handoff?).to be false
          expect(result.intent).to eq(:clarification)
          expect(result.content).to eq(I18n.t('ai.agent.clarification_request', query: 'factura'))
        end
      end

      it 'asks for clarification in Arabic for Arabic locale' do
        I18n.with_locale(:ar) do
          result = described_class.call(
            account: account,
            portal: portal,
            inbox: inbox,
            query: 'فاتورة'
          )

          expect(result.handoff?).to be false
          expect(result.intent).to eq(:clarification)
          expect(result.content).to eq(I18n.t('ai.agent.clarification_request', query: 'فاتورة'))
        end
      end

      it 'triggers fallback handoff when LLM returns [NO_DOCUMENTATION_FOUND]' do
        allow(Ai::Client).to receive(:call).and_return('[NO_DOCUMENTATION_FOUND]')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'Do you offer spaceships?'
        )

        expect(result.handoff?).to be true
        expect(result.intent).to eq(:fallback_handoff)
        expect(result.content).to eq('Sorry, I am unable to answer this question. Connecting you to a human agent...')
      end

      it 'triggers human handoff when LLM detects nuanced escalation via [HUMAN_HANDOFF_REQUESTED]' do
        allow(Ai::Client).to receive(:call).and_return('[HUMAN_HANDOFF_REQUESTED]')

        result = described_class.call(
          account: account,
          portal: portal,
          inbox: inbox,
          query: 'I despise artificial bots, get me someone with a pulse right now'
        )

        expect(result.handoff?).to be true
        expect(result.intent).to eq(:human_requested)
        expect(result.content).to eq("I'm connecting you with a human agent now. Someone from our team will be with you shortly.")
      end
    end
  end
end

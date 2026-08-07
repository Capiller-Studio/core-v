FactoryBot.define do
  factory :ai_agent, class: 'Ai::Agent' do
    account
    name { 'Test Agent' }
    max_exchanges { 10 }
    confidence_threshold { 0.8 }
    status { :active }
    agent_type { :custom }
    tone { :friendly }
  end
  
  factory :ai_agent_translation, class: 'Ai::AgentTranslation' do
    association :agent, factory: :ai_agent
    locale { 'en' }
    greeting_message { 'Hello' }
    handoff_message { 'Transferring you' }
    fallback_message { 'I am not sure' }
  end
end

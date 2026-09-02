# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module AiAgentsAndCopilot
        def self.category
          {
            key: :ai_agents_and_copilot,
            icon_key: "bot",
            position: 4,
            translations: {
              en: {
                name: "AI Agents & AI Copilot",
                description: "Deploy 24/7 autonomous AI support agents, train on knowledge base articles, and empower human agents with real-time AI Copilot assistance."
              },
              de: {
                name: "KI-Agenten & KI-Copilot",
                description: "Setzen Sie autonome 24/7 KI-Support-Agenten ein und unterstützen Sie menschliche Mitarbeiter mit KI-Copilot."
              },
              es: {
                name: "Agentes de IA y Copiloto de IA",
                description: "Implemente agentes de soporte de IA autónomos 24/7 y capacite a sus agentes humanos con asistencia en tiempo real."
              },
              fr: {
                name: "Agents IA et Copilote IA",
                description: "Déployez des agents IA autonomes 24/7 et assistez vos conseillers avec le Copilote IA en temps réel."
              },
              "pt-BR": {
                name: "Agentes de IA e Copiloto de IA",
                description: "Implemente agentes de IA autônomos 24/7 e capacite atendentes humanos com o Copiloto de IA em tempo real."
              },
              ar: {
                name: "وكلاء الذكاء الاصطناعي والمساعد الذكي (Copilot)",
                description: "انشر وكلاء دعم ذاتيين يعملون على مدار الساعة بالذكاء الاصطناعي، ودربهم على مقالات مركز المساعدة، وعزز إنتاجية الفريق."
              },
              ko: {
                name: "AI 상담 에이전트 및 AI 코파일럿",
                description: "24시간 자율 대응 AI 고객 지원 에이전트를 구축하고, 실시간 AI 코파일럿으로 상담원의 생산성을 극대화합니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :autonomous_ai_agents,
              position: 1,
              translations: {
                en: {
                  title: "Deploying Autonomous AI Support Agents",
                  content: <<~HTML
                    <p>Deskbolic Autonomous AI Agents can resolve up to 70% of routine customer inquiries without human intervention.</p>
                    <h3>Setting Up an AI Agent</h3>
                    <ol>
                      <li>Navigate to <strong>AI Agent &rarr; Agents</strong> and click <strong>+ Create AI Agent</strong>.</li>
                      <li>Define your agent's persona, tone of voice, greeting messages, and system instructions.</li>
                      <li>Set guardrails, escalation triggers (e.g. sentiment threshold or customer request for human), and assign to specific inboxes.</li>
                    </ol>
                  HTML
                },
                de: {
                  title: "Autonome KI-Support-Agenten einsetzen",
                  content: "<p>Deskbolic KI-Agenten beantworten Kundenfragen rund um die Uhr vollautomatisch basierend auf Ihren Wissensartikeln.</p>"
                },
                es: {
                  title: "Implementación de Agentes de Soporte de IA",
                  content: "<p>Los agentes de IA de Deskbolic resuelven consultas frecuentes de clientes de forma totalmente autónoma 24/7.</p>"
                },
                fr: {
                  title: "Déploiement d'Agents IA Autonomes",
                  content: "<p>Les agents IA Deskbolic répondent automatiquement aux questions des clients 24/7 en s'appuyant sur votre base de connaissances.</p>"
                },
                "pt-BR": {
                  title: "Implementando Agentes de IA Autônomos",
                  content: "<p>Os agentes de IA do Deskbolic resolvem dúvidas de clientes automaticamente 24 horas por dia, 7 dias por semana.</p>"
                },
                ar: {
                  title: "نشر وكلاء دعم الذكاء الاصطناعي الذاتيين",
                  content: "<p>يقوم وكلاء الذكاء الاصطناعي في Deskbolic بحل ما يصل إلى 70% من استفسارات العملاء الروتينية على مدار الساعة دون تدخل بشري.</p>"
                },
                ko: {
                  title: "자율 AI 상담 에이전트 배포 가이드",
                  content: "<p>Deskbolic 자율 AI 에이전트는 지식 기반 문서를 학습하여 24시간 365일 고객 문의의 70% 이상을 자동 해결합니다.</p>"
                }
              }
            },
            {
              key: :ai_copilot_assistant,
              position: 2,
              translations: {
                en: {
                  title: "AI Copilot: Real-Time Agent Assistance",
                  content: <<~HTML
                    <p>AI Copilot assists human agents inside the conversation composer with intelligent reply drafting, tone adjustment, and summarization.</p>
                    <h3>Key Capabilities</h3>
                    <ul>
                      <li><strong>Suggest Reply:</strong> Generates context-aware response drafts based on conversation history and knowledge base.</li>
                      <li><strong>Fix Spelling &amp; Grammar:</strong> Instantly polishes drafted messages.</li>
                      <li><strong>Adjust Tone:</strong> Transform drafts to sound friendly, formal, concise, or empathetic.</li>
                      <li><strong>Summarize Conversation:</strong> Creates bullet-point executive summaries for handover between agents.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "KI-Copilot: Echtzeit-Unterstützung für Agenten",
                  content: "<p>Der KI-Copilot unterstützt Agenten beim Verfassen von Antworten, Anpassen des Tons und Zusammenfassen von Konversationen.</p>"
                },
                es: {
                  title: "Copiloto de IA: Asistencia en Tiempo Real",
                  content: "<p>El Copiloto de IA ayuda a los agentes a redactar respuestas, ajustar el tono y resumir conversaciones.</p>"
                },
                fr: {
                  title: "Copilote IA: Assistance en Temps Réel",
                  content: "<p>Le Copilote IA aide les agents à rédiger des réponses, ajuster le ton et résumer les conversations.</p>"
                },
                "pt-BR": {
                  title: "Copiloto de IA: Assistência em Tempo Real",
                  content: "<p>O Copiloto de IA auxilia atendentes a redigir respostas, ajustar tom de voz e resumir atendimentos.</p>"
                },
                ar: {
                  title: "المساعد الذكي (AI Copilot): دعم فوري للوكلاء",
                  content: "<p>يساعد Copilot الوكلاء في صياغة الردود الذكية، وتعديل نبرة الصوت، وتلخيص المحادثات الطويلة بنقرة واحدة.</p>"
                },
                ko: {
                  title: "AI 코파일럿: 상담원 실시간 작성 어시스턴트",
                  content: "<p>AI 코파일럿은 대화 내역을 바탕으로 최적의 답변 초안을 추천하고, 문맥 요약 및 정중한 어조 수정을 실시간 지원합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module CsatAndAnalytics
        def self.category
          {
            key: :csat_and_analytics,
            icon_key: "bar-chart-2",
            position: 8,
            translations: {
              en: {
                name: "CSAT Surveys & Analytics",
                description: "Track customer satisfaction (CSAT) ratings, monitor agent performance metrics, and analyze conversation volume trends."
              },
              de: {
                name: "CSAT-Umfragen & Analysen",
                description: "Messen Sie die Kundenzufriedenheit und analysieren Sie Reaktionszeiten und Leistungskennzahlen."
              },
              es: {
                name: "Encuestas CSAT y Análisis",
                description: "Mida la satisfacción del cliente y analice métricas de rendimiento del equipo de soporte."
              },
              fr: {
                name: "Enquêtes CSAT et Statistiques",
                description: "Mesurez la satisfaction client et analysez les indicateurs de performance de vos conseillers."
              },
              "pt-BR": {
                name: "Pesquisas CSAT e Relatórios",
                description: "Monitore a satisfação do cliente (CSAT), tempos de resposta e indicadores de desempenho da equipe."
              },
              ar: {
                name: "استطلاعات رضا العملاء (CSAT) والتحليلات",
                description: "تتبع تقييمات رضا العملاء، وراقب مؤشرات أداء الوكلاء، وحلل اتجاهات حجم المحادثات."
              },
              ko: {
                name: "고객 만족도(CSAT) 및 통계 분석",
                description: "상담 완료 후 고객 만족도(CSAT) 자동 설문 조사, 응답 시간 통계 및 상담원 성과 분석 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :csat_surveys_setup,
              position: 1,
              translations: {
                en: {
                  title: "Automated CSAT Customer Satisfaction Surveys",
                  content: <<~HTML
                    <p>Collect immediate feedback when conversations are resolved to measure service quality.</p>
                    <h3>Enabling CSAT Surveys</h3>
                    <p>Go to <strong>Settings &rarr; CSAT Surveys</strong> and toggle automatic delivery. You can customize question text, rating scale (1-5 stars or emoji faces), and optional follow-up comment prompts.</p>
                  HTML
                },
                de: {
                  title: "Automatische CSAT-Zufriedenheitsumfragen",
                  content: "<p>Sammeln Sie nach jeder gelösten Konversation direktes Kundenfeedback mit CSAT-Umfragen.</p>"
                },
                es: {
                  title: "Encuestas Automatizadas de Satisfacción CSAT",
                  content: "<p>Recopile comentarios de clientes cuando se resuelve una conversación mediante encuestas CSAT.</p>"
                },
                fr: {
                  title: "Enquêtes de Satisfaction Client CSAT Automatisées",
                  content: "<p>Recueillez les avis de vos clients dès la résolution d'une conversation grâce aux enquêtes CSAT.</p>"
                },
                "pt-BR": {
                  title: "Pesquisas de Satisfação CSAT Automatizadas",
                  content: "<p>Colete avaliações dos clientes automaticamente ao finalizar os atendimentos com o CSAT.</p>"
                },
                ar: {
                  title: "استطلاعات رضا العملاء التلقائية (CSAT)",
                  content: "<p>اجمع آراء العملاء الفورية عند حل المحادثات لقياس جودة الخدمة ورضا العملاء.</p>"
                },
                ko: {
                  title: "고객 만족도(CSAT) 자동 설문 조사 설정",
                  content: "<p>대화가 해결 완료(resolved)되면 고객에게 별점/이모지 기반 만족도 평가 설문을 자동 발송합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

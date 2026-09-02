# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module AutomationsAndProductivity
        def self.category
          {
            key: :automations_and_productivity,
            icon_key: "zap",
            position: 5,
            translations: {
              en: {
                name: "Automations, SLAs & Productivity",
                description: "Automate repetitive workflows, enforce SLA response targets, configure business hours, and speed up replies with macros and canned responses."
              },
              de: {
                name: "Automatisierungen, SLAs & Produktivität",
                description: "Automatisieren Sie Workflows, setzen Sie SLAs durch und nutzen Sie Makros und Textbausteine."
              },
              es: {
                name: "Automatizaciones, SLAs y Productividad",
                description: "Automatice flujos de trabajo, aplique acuerdos de nivel de servicio (SLA) y configure respuestas rápidas."
              },
              fr: {
                name: "Automatisations, SLA et Productivité",
                description: "Automatisez vos flux de travail, respectez les délais SLA et gagnez du temps avec les macros."
              },
              "pt-BR": {
                name: "Automações, SLAs e Produtividade",
                description: "Automatize fluxos de trabalho, monitore metas de SLA e agilize respostas com macros e mensagens prontas."
              },
              ar: {
                name: "الأتمتة وسياسات SLA والإنتاجية",
                description: "أتمتة سير العمل المتكرر، وتطبيق سياسات اتفاقية مستوى الخدمة (SLA)، وتكوين ساعات العمل والردود الجاهزة."
              },
              ko: {
                name: "자동화 규칙, SLA 및 생산성 도구",
                description: "반복적인 업무 자동화, SLA 응답 목표 준수, 업무 시간 설정 및 매크로/상용구를 통한 빠른 상담 지원 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :automation_rules,
              position: 1,
              translations: {
                en: {
                  title: "Automation Rules & Event Triggers",
                  content: <<~HTML
                    <p>Automation rules trigger actions automatically based on incoming conversation events and custom conditions.</p>
                    <h3>Common Automation Workflows</h3>
                    <ul>
                      <li><strong>Keyword Routing:</strong> Automatically assign conversations containing words like "refund" or "invoice" to the Billing Team.</li>
                      <li><strong>VIP Routing:</strong> Auto-tag and assign high-priority SLA policies to customers with custom attribute <code>plan = Enterprise</code>.</li>
                      <li><strong>Auto-Responders:</strong> Send customized out-of-office acknowledgments during non-business hours.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Automatisierungsregeln & Trigger",
                  content: "<p>Automatisierungsregeln lösen Aktionen basierend auf Ereignissen und Bedingungen automatisch aus.</p>"
                },
                es: {
                  title: "Reglas de Automatización y Disparadores",
                  content: "<p>Las reglas de automatización ejecutan acciones basadas en eventos y condiciones personalizadas.</p>"
                },
                fr: {
                  title: "Règles d'Automatisation et Déclencheurs",
                  content: "<p>Les règles d'automatisation déclenchent des actions basées sur les événements des conversations.</p>"
                },
                "pt-BR": {
                  title: "Regras de Automação e Gatilhos",
                  content: "<p>As regras de automação executam ações com base em eventos e condições personalizadas.</p>"
                },
                ar: {
                  title: "قواعد الأتمتة ومحفزات الأحداث",
                  content: "<p>تطلق قواعد الأتمتة إجراءات تلقائية بناءً على أحداث المحادثات الواردة والشروط المخصصة.</p>"
                },
                ko: {
                  title: "자동화 규칙 및 이벤트 트리거",
                  content: "<p>특정 키워드, 고객 등급, 인입 채널 등 조건에 따라 대화를 자동 배정하고 태그를 지정하는 자동화 규칙을 구축합니다.</p>"
                }
              }
            },
            {
              key: :sla_policies,
              position: 2,
              translations: {
                en: {
                  title: "SLA Policies & Escalation Targets",
                  content: <<~HTML
                    <p>Service Level Agreements (SLAs) ensure your support team meets target First Response Time and Resolution Time benchmarks.</p>
                    <h3>Setting Up SLAs</h3>
                    <p>Navigate to <strong>Settings &rarr; SLA Policies</strong> to define target hours by priority level (Urgent: 15 mins, High: 1 hour, Medium: 4 hours, Low: 24 hours). Configure auto-escalation alerts when an SLA breach is imminent.</p>
                  HTML
                },
                de: {
                  title: "SLA-Richtlinien & Eskalationen",
                  content: "<p>Service Level Agreements (SLAs) stellen sicher, dass Reaktions- und Lösungszeiten eingehalten werden.</p>"
                },
                es: {
                  title: "Políticas de SLA y Escalaciones",
                  content: "<p>Los Acuerdos de Nivel de Servicio (SLA) aseguran que el equipo cumpla con los tiempos de respuesta y resolución.</p>"
                },
                fr: {
                  title: "Politiques SLA et Délais de Résolution",
                  content: "<p>Les politiques SLA garantissent le respect des temps de première réponse et de résolution.</p>"
                },
                "pt-BR": {
                  title: "Políticas de SLA e Metas de Atendimento",
                  content: "<p>Os Acordos de Nível de Serviço (SLA) garantem que a equipe cumpra os prazos de primeira resposta e resolução.</p>"
                },
                ar: {
                  title: "سياسات اتفاقية مستوى الخدمة (SLA) والتصعيد",
                  content: "<p>تضمن اتفاقيات مستوى الخدمة (SLAs) التزام فريق الدعم بأوقات الاستجابة الأولى وأهداف وقت الحل المحددة.</p>"
                },
                ko: {
                  title: "SLA 정책 및 단계별 에스컬레이션",
                  content: "<p>우선순위별 최초 응답 시간 및 해결 목표 시간을 설정하여 고객 응대 SLA 준수율을 관리합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

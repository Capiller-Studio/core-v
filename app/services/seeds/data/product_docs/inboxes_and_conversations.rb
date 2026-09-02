# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module InboxesAndConversations
        def self.category
          {
            key: :inboxes_and_conversations,
            icon_key: "inbox",
            position: 2,
            translations: {
              en: {
                name: "Inboxes & Conversations",
                description: "Master the unified omnichannel inbox, conversation lifecycle, assigning tickets, private internal notes, and real-time collaboration."
              },
              de: {
                name: "Postfächer & Konversationen",
                description: "Verwalten Sie das einheitliche Postfach, Zuweisungen, interne Notizen und den Konversationslebenszyklus."
              },
              es: {
                name: "Bandejas y Conversaciones",
                description: "Domine la bandeja omnicanal unificada, asignaciones, notas privadas y el ciclo de vida de las conversaciones."
              },
              fr: {
                name: "Boîtes et Conversations",
                description: "Maîtrisez la boîte unifiée, l'attribution des tickets, les notes internes et la collaboration en temps réel."
              },
              "pt-BR": {
                name: "Caixas de Entrada e Conversas",
                description: "Domine a caixa multicanal unificada, atribuições, notas internas e o ciclo de vida dos atendimentos."
              },
              ar: {
                name: "صناديق الوارد والمحادثات",
                description: "تعلم كيفية إدارة صندوق الوارد الموحد متعدد القنوات، وتعيين التذاكر، والملاحظات الخاصة، وحالة المحادثات."
              },
              ko: {
                name: "받은 편지함 및 대화 관리",
                description: "통합 옴니채널 받은 편지함 활용법, 대화 담당자 배정, 내부 비공개 메모 및 실시간 협업 기능 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :unified_inbox_views,
              position: 1,
              translations: {
                en: {
                  title: "Unified Inboxes & Smart Filter Views",
                  content: <<~HTML
                    <p>Deskbolic aggregates all customer messages across all communication channels into a single unified queue.</p>
                    <h3>Smart Views</h3>
                    <ul>
                      <li><strong>Mine:</strong> Conversations specifically assigned to you.</li>
                      <li><strong>Unassigned:</strong> Incoming customer tickets awaiting triage and agent assignment.</li>
                      <li><strong>All:</strong> Complete workspace conversation stream across all channels.</li>
                      <li><strong>Mentions:</strong> Conversations where a teammate tagged you in a private note (<code>@username</code>).</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Einheitliche Postfächer & Ansichten",
                  content: "<p>Deskbolic bündelt alle Kundennachrichten in einer zentralen Ansicht mit intelligenten Filtern (Meine, Nicht zugewiesen, Alle, Erwähnungen).</p>"
                },
                es: {
                  title: "Bandeja Unificada y Vistas Inteligentes",
                  content: "<p>Deskbolic reúne todos los mensajes de clientes en una cola unificada con vistas inteligentes (Míos, Sin asignar, Todos, Menciones).</p>"
                },
                fr: {
                  title: "Boîte Unifiée et Vues Intelligentes",
                  content: "<p>Deskbolic regroupe tous les messages dans une file d'attente unifiée avec des vues intelligentes.</p>"
                },
                "pt-BR": {
                  title: "Caixa Unificada e Visualizações Inteligentes",
                  content: "<p>O Deskbolic reúne todas as mensagens em uma fila unificada com filtros inteligentes (Meus, Não atribuídos, Todos, Menções).</p>"
                },
                ar: {
                  title: "صناديق الوارد الموحدة وطرق العرض الذكية",
                  content: "<p>يجمع Deskbolic جميع رسائل العملاء عبر جميع القنوات في قائمة انتظار موحدة واحدة مع طرق عرض ذكية.</p>"
                },
                ko: {
                  title: "통합 받은 편지함 및 스마트 필터 뷰",
                  content: "<p>모든 채널의 고객 문의를 단일 큐로 취합하며, 내 담당/미배정/전체/멘션 스마트 필터 뷰를 제공합니다.</p>"
                }
              }
            },
            {
              key: :conversation_lifecycle,
              position: 2,
              translations: {
                en: {
                  title: "Conversation Lifecycle & Statuses",
                  content: <<~HTML
                    <p>Every conversation moves through distinct lifecycle stages to ensure no customer inquiry slips through the cracks:</p>
                    <ul>
                      <li><strong>Active / Open:</strong> Awaiting an agent or customer reply.</li>
                      <li><strong>Snoozed:</strong> Temporarily paused until a specific date/time (e.g. waiting for customer verification or follow-up).</li>
                      <li><strong>Resolved:</strong> Successfully concluded and closed. If the customer sends another message, the conversation reopens automatically.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Konversationslebenszyklus & Status",
                  content: "<p>Jede Konversation durchläuft Phasen: Offen (Aktiv), Zurückgestellt (Snoozed) und Gelöst (Resolved).</p>"
                },
                es: {
                  title: "Ciclo de Vida y Estados de la Conversación",
                  content: "<p>Cada conversación avanza por estados: Abierta (Activa), Pospuesta (Snoozed) y Resuelta (Cerrada).</p>"
                },
                fr: {
                  title: "Cycle de Vie et Statuts des Conversations",
                  content: "<p>Chaque conversation passe par des étapes: Ouverte, En attente et Résolue.</p>"
                },
                "pt-BR": {
                  title: "Ciclo de Vida e Status das Conversas",
                  content: "<p>Cada atendimento passa por estágios: Aberto, Adiado (Snoozed) e Resolvido.</p>"
                },
                ar: {
                  title: "دورة حياة المحادثة وحالاتها",
                  content: "<p>تمر كل محادثة بمراحل: نشطة (مفتوحة)، مؤجلة (Snoozed)، ومحلولة (مغلقة).</p>"
                },
                ko: {
                  title: "대화 수명 주기 및 상태 관리",
                  content: "<p>모든 상담 대화는 진행 중(Active), 일시정지(Snoozed), 해결 완료(Resolved) 상태로 체계적으로 관리됩니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

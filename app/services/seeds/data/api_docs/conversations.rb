# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Conversations
        def self.category
          {
            key: :conversations,
            icon_key: "message-square",
            position: 7,
            api_reference: true,
            translations: {
              en: {
                name: "Conversations",
                description: "Core endpoints to list, create, assign, label, snooze, resolve, and manage omnichannel support conversations."
              },
              de: {
                name: "Konversationen",
                description: "Zentrale Endpunkte zum Erstellen, Zuweisen, Kennzeichnen, Zurückstellen und Lösen von Support-Konversationen."
              },
              es: {
                name: "Conversaciones",
                description: "Puntos finales principales para listar, crear, asignar, etiquetar, posponer y resolver conversaciones de soporte."
              },
              fr: {
                name: "Conversations",
                description: "Points de terminaison pour lister, créer, assigner, étiqueter, mettre en attente et résoudre les conversations."
              },
              "pt-BR": {
                name: "Conversas",
                description: "Endpoints principais para listar, criar, atribuir, rotular, adiar e resolver conversas de suporte."
              },
              ar: {
                name: "المحادثات",
                description: "نقاط النهاية الأساسية لسرد، وإنشاء، وتعيين، وتصنيف، وتأجيل، وحل محادثات الدعم متعددة القنوات."
              },
              ko: {
                name: "대화 관리",
                description: "옴니채널 고객 상담 대화 목록 조회, 생성, 담당자 배정, 라벨 관리, 일시정지 및 해결 완료 처리 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :conversations_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/conversations",
                "api_parameters" => [
                  { "name" => "status", "type" => "string", "description" => "Filter by status: 'active', 'closed', 'snoozed', 'resolved'", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-100, default: 20)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of conversations",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"cnv_777\",\n      \"identifier\": \"CNV-1029\",\n      \"title\": \"Payment Gateway Error\",\n      \"status\": \"active\",\n      \"priority\": \"high\",\n      \"inbox_id\": \"inb_901\",\n      \"assignee_id\": \"usr_888\",\n      \"team_id\": \"tm_301\",\n      \"created_at\": \"2026-09-02T13:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 8,\n    \"total_count\": 152,\n    \"per_page\": 20\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Conversations",
                  content: "<p>Returns a paginated list of conversations in the workspace. Supports filtering by status (active, closed, snoozed, resolved).</p>"
                },
                de: {
                  title: "Konversationen auflisten",
                  content: "<p>Gibt eine paginierte Liste von Konversationen im Arbeitsbereich zurück.</p>"
                },
                es: {
                  title: "Listar Conversaciones",
                  content: "<p>Devuelve una lista paginada de conversaciones en el espacio de trabajo.</p>"
                },
                fr: {
                  title: "Lister les conversations",
                  content: "<p>Renvoie une liste paginée de conversations dans l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Listar Conversas",
                  content: "<p>Retorna uma lista paginada de conversas no espaço de trabalho.</p>"
                },
                ar: {
                  title: "عرض قائمة المحادثات",
                  content: "<p>يعيد قائمة مقسمة إلى صفحات بالمحادثات في مساحة العمل مع دعم التصفية حسب الحالة.</p>"
                },
                ko: {
                  title: "대화 목록 조회",
                  content: "<p>워크스페이스의 대화 목록을 페이지네이션하여 반환합니다. 상태별(active, closed, snoozed, resolved) 필터링을 지원합니다.</p>"
                }
              }
            },
            {
              key: :conversations_get,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/conversations/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Conversation details",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"identifier\": \"CNV-1029\",\n    \"title\": \"Payment Gateway Error\",\n    \"status\": \"active\",\n    \"priority\": \"high\",\n    \"inbox\": {\n      \"id\": \"inb_901\",\n      \"name\": \"Support Email\"\n    },\n    \"assignee\": {\n      \"id\": \"usr_888\",\n      \"name\": \"Sarah Connor\"\n    },\n    \"labels\": [\n      { \"id\": \"lbl_55\", \"title\": \"Billing\", \"color\": \"#EF4444\" }\n    ]\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Conversation Details",
                  content: "<p>Retrieves complete conversation metadata including assigned agent, team, labels, priority, and inbox details.</p>"
                },
                de: {
                  title: "Konversationsdetails abrufen",
                  content: "<p>Ruft vollständige Metadaten einer Konversation ab.</p>"
                },
                es: {
                  title: "Obtener Detalles de la Conversación",
                  content: "<p>Obtiene los metadatos completos de una conversación.</p>"
                },
                fr: {
                  title: "Obtenir les détails de la conversation",
                  content: "<p>Récupère les métadonnées complètes d'une conversation.</p>"
                },
                "pt-BR": {
                  title: "Obter Detalhes da Conversa",
                  content: "<p>Recupera os metadados completos de uma conversa.</p>"
                },
                ar: {
                  title: "عرض تفاصيل المحادثة",
                  content: "<p>يسترد البيانات الوصفية الكاملة للمحادثة بما في ذلك الوكيل المعين والفريق والتسميات.</p>"
                },
                ko: {
                  title: "대화 상세 정보 조회",
                  content: "<p>담당 상담원, 배정 팀, 라벨, 우선순위 및 받은 편지함을 포함한 대화 상세 정보를 조회합니다.</p>"
                }
              }
            },
            {
              key: :conversations_create,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations",
                "api_parameters" => [
                  { "name" => "inbox_id", "type" => "string", "description" => "Target inbox UUID", "required" => true },
                  { "name" => "customer_id", "type" => "string", "description" => "Customer UUID", "required" => true },
                  { "name" => "status", "type" => "string", "description" => "Initial status: 'active', 'closed', 'snoozed', 'resolved'", "required" => false },
                  { "name" => "priority", "type" => "string", "description" => "Priority: 'low', 'medium', 'high', 'urgent'", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Conversation created successfully",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_778\",\n    \"identifier\": \"CNV-1030\",\n    \"status\": \"active\",\n    \"priority\": \"medium\",\n    \"inbox_id\": \"inb_901\",\n    \"created_at\": \"2026-09-02T14:15:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Conversation",
                  content: "<p>Creates a new conversation thread on behalf of a customer in the specified inbox.</p>"
                },
                de: {
                  title: "Konversation erstellen",
                  content: "<p>Erstellt einen neuen Konversations-Thread für einen Kunden im angegebenen Postfach.</p>"
                },
                es: {
                  title: "Crear Conversación",
                  content: "<p>Crea un nuevo hilo de conversación para un cliente en la bandeja de entrada especificada.</p>"
                },
                fr: {
                  title: "Créer une conversation",
                  content: "<p>Crée un nouveau fil de conversation pour un client dans la boîte de réception spécifiée.</p>"
                },
                "pt-BR": {
                  title: "Criar Conversa",
                  content: "<p>Cria um novo tópico de conversa para um cliente na caixa de entrada especificada.</p>"
                },
                ar: {
                  title: "إنشاء محادثة جديدة",
                  content: "<p>ينشئ سلسلة محادثة جديدة نيابة عن العميل في صندوق الوارد المحدد.</p>"
                },
                ko: {
                  title: "새 대화 생성",
                  content: "<p>지정된 받은 편지함에서 고객의 새 상담 대화 스레드를 생성합니다.</p>"
                }
              }
            },
            {
              key: :conversations_patch,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/conversations/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "status", "type" => "string", "description" => "'active', 'closed', 'snoozed', 'resolved'", "required" => false },
                  { "name" => "priority", "type" => "string", "description" => "'low', 'medium', 'high', 'urgent'", "required" => false },
                  { "name" => "title", "type" => "string", "description" => "Custom conversation subject / title", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Conversation updated",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"status\": \"resolved\",\n    \"priority\": \"urgent\",\n    \"title\": \"Refund Processed\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Conversation",
                  content: "<p>Updates core conversation attributes such as status, priority, or subject title.</p>"
                },
                de: {
                  title: "Konversation aktualisieren",
                  content: "<p>Aktualisiert Konversationsattribute wie Status, Priorität oder Betreff.</p>"
                },
                es: {
                  title: "Actualizar Conversación",
                  content: "<p>Actualiza los atributos de la conversación como estado, prioridad o título.</p>"
                },
                fr: {
                  title: "Mettre à jour la conversation",
                  content: "<p>Met à jour les attributs de la conversation tels que le statut, la priorité ou le titre.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Conversa",
                  content: "<p>Atualiza os atributos da conversa, como status, prioridade ou título.</p>"
                },
                ar: {
                  title: "تحديث المحادثة",
                  content: "<p>يقوم بتحديث سمات المحادثة مثل الحالة والأولوية والعنوان.</p>"
                },
                ko: {
                  title: "대화 속성 수정",
                  content: "<p>대화 상태, 우선순위 및 제목 등의 핵심 속성을 수정합니다.</p>"
                }
              }
            },
            {
              key: :conversations_assign,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:id/assign",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "assignee_id", "type" => "string", "description" => "Agent User UUID (or null to unassign)", "required" => false },
                  { "name" => "team_id", "type" => "string", "description" => "Team UUID (or null to unassign)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Assignment updated",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"assignee_id\": \"usr_888\",\n    \"team_id\": \"tm_301\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Assign Conversation to Agent / Team",
                  content: "<p>Assigns or reassigns the conversation to a specific agent user and/or specialized team.</p>"
                },
                de: {
                  title: "Konversation zuweisen",
                  content: "<p>Weist die Konversation einem Agenten oder Team zu.</p>"
                },
                es: {
                  title: "Asignar Conversación",
                  content: "<p>Asigna la conversación a un agente o equipo específico.</p>"
                },
                fr: {
                  title: "Assigner la conversation",
                  content: "<p>Assigne la conversation à un agent ou à une équipe.</p>"
                },
                "pt-BR": {
                  title: "Atribuir Conversa",
                  content: "<p>Atribui a conversa a um atendente ou equipe específica.</p>"
                },
                ar: {
                  title: "تعيين المحادثة لوكيل أو فريق",
                  content: "<p>يعين المحادثة لوكيل دعم محدد أو فريق متخصص.</p>"
                },
                ko: {
                  title: "대화 담당자 / 팀 배정",
                  content: "<p>대화를 특정 상담원 또는 전문 팀에 배정하거나 배정을 해제합니다.</p>"
                }
              }
            },
            {
              key: :conversations_labels_add,
              article_type: :api_endpoint,
              position: 6,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:id/labels",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "label_id", "type" => "string", "description" => "Existing label UUID", "required" => false },
                  { "name" => "label_title", "type" => "string", "description" => "Label title to find or create", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Label applied",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"labels\": [\n      { \"id\": \"lbl_12\", \"title\": \"Bug Report\", \"color\": \"#EF4444\" }\n    ]\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Add Label to Conversation",
                  content: "<p>Applies a tag or label to a conversation for categorization and workflow routing.</p>"
                },
                de: {
                  title: "Label zu Konversation hinzufügen",
                  content: "<p>Fügt einer Konversation ein Label hinzu.</p>"
                },
                es: {
                  title: "Agregar Etiqueta a Conversación",
                  content: "<p>Aplica una etiqueta a la conversación para categorización.</p>"
                },
                fr: {
                  title: "Ajouter une étiquette à la conversation",
                  content: "<p>Applique une étiquette à la conversation pour la catégorisation.</p>"
                },
                "pt-BR": {
                  title: "Adicionar Rótulo à Conversa",
                  content: "<p>Aplica um rótulo à conversa para categorização.</p>"
                },
                ar: {
                  title: "إضافة تسمية إلى المحادثة",
                  content: "<p>يضيف تصنيفًا أو علامة للمحادثة للتصنيف وتوجيه سير العمل.</p>"
                },
                ko: {
                  title: "대화 라벨 추가",
                  content: "<p>대화의 분류 및 워크플로 자동화를 위해 태그(라벨)를 부여합니다.</p>"
                }
              }
            },
            {
              key: :conversations_labels_remove,
              article_type: :api_endpoint,
              position: 7,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/conversations/:id/labels/:label_id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "label_id", "type" => "string", "description" => "Label UUID to remove", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Label removed",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"labels\": []\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Remove Label from Conversation",
                  content: "<p>Removes an applied label from the conversation.</p>"
                },
                de: {
                  title: "Label von Konversation entfernen",
                  content: "<p>Entfernt ein angewendetes Label von der Konversation.</p>"
                },
                es: {
                  title: "Eliminar Etiqueta de la Conversación",
                  content: "<p>Elimina una etiqueta aplicada de la conversación.</p>"
                },
                fr: {
                  title: "Supprimer l'étiquette de la conversation",
                  content: "<p>Supprime une étiquette appliquée de la conversation.</p>"
                },
                "pt-BR": {
                  title: "Remover Rótulo da Conversa",
                  content: "<p>Remove um rótulo aplicado da conversa.</p>"
                },
                ar: {
                  title: "إزالة التسمية من المحادثة",
                  content: "<p>يزيل التصنيف أو العلامة المطبقة من المحادثة.</p>"
                },
                ko: {
                  title: "대화 라벨 제거",
                  content: "<p>대화에 적용된 특정 라벨을 제거합니다.</p>"
                }
              }
            },
            {
              key: :conversations_snooze,
              article_type: :api_endpoint,
              position: 8,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:id/snooze",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "snoozed_until", "type" => "datetime", "description" => "ISO 8601 Datetime string when conversation reopens", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Conversation snoozed",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"status\": \"snoozed\",\n    \"snoozed_until\": \"2026-09-05T09:00:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Snooze Conversation",
                  content: "<p>Temporarily snoozes a conversation until the specified datetime, reopening it automatically when the time arrives or a customer replies.</p>"
                },
                de: {
                  title: "Konversation zurückstellen (Snooze)",
                  content: "<p>Stellt eine Konversation bis zum angegebenen Zeitpunkt zurück.</p>"
                },
                es: {
                  title: "Posponer Conversación (Snooze)",
                  content: "<p>Pospone temporalmente una conversación hasta la fecha y hora especificadas.</p>"
                },
                fr: {
                  title: "Mettre en attente la conversation (Snooze)",
                  content: "<p>Met temporairement une conversation en attente jusqu'à la date spécifiée.</p>"
                },
                "pt-BR": {
                  title: "Adiar Conversa (Snooze)",
                  content: "<p>Adia temporariamente uma conversa até a data e hora especificadas.</p>"
                },
                ar: {
                  title: "تأجيل المحادثة (Snooze)",
                  content: "<p>يؤجل المحادثة مؤقتًا حتى تاريخ ووقت محددين، ويعيد فتحها تلقائيًا عند انتهاء الوقت أو رد العميل.</p>"
                },
                ko: {
                  title: "대화 일시정지 (Snooze)",
                  content: "<p>지정된 일시까지 대화를 일시정지 상태로 변경하며, 시간이 도래하거나 고객이 답변하면 자동으로 재개됩니다.</p>"
                }
              }
            },
            {
              key: :conversations_resolve,
              article_type: :api_endpoint,
              position: 9,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:id/resolve",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Conversation resolved",
                    "body" => "{\n  \"data\": {\n    \"id\": \"cnv_777\",\n    \"status\": \"resolved\",\n    \"resolved_at\": \"2026-09-02T14:30:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Resolve Conversation",
                  content: "<p>Marks the conversation as resolved, triggering CSAT satisfaction surveys if configured.</p>"
                },
                de: {
                  title: "Konversation lösen",
                  content: "<p>Markiert die Konversation als gelöst und löst ggf. CSAT-Umfragen aus.</p>"
                },
                es: {
                  title: "Resolver Conversación",
                  content: "<p>Marca la conversación como resuelta, activando encuestas CSAT si están configuradas.</p>"
                },
                fr: {
                  title: "Résoudre la conversation",
                  content: "<p>Marque la conversation comme résolue et déclenche les enquêtes CSAT configurées.</p>"
                },
                "pt-BR": {
                  title: "Resolver Conversa",
                  content: "<p>Marca a conversa como resolvida e dispara pesquisas de satisfação CSAT.</p>"
                },
                ar: {
                  title: "حل المحادثة وإغلاقها",
                  content: "<p>يعين المحادثة على أنها محلولة، ويطلق استطلاعات رضا العملاء CSAT إذا تم تكوينها.</p>"
                },
                ko: {
                  title: "대화 해결 완료 처리",
                  content: "<p>대화를 해결 완료(resolved) 상태로 변경하며, 설정된 경우 고객 만족도(CSAT) 설문조사를 트리거합니다.</p>"
                }
              }
            },
            {
              key: :conversations_typing,
              article_type: :api_endpoint,
              position: 10,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:id/typing",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "typing", "type" => "boolean", "description" => "True when typing, false when stopped", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Typing indicator broadcasted",
                    "body" => "{\n  \"data\": {\n    \"typing\": true,\n    \"conversation_id\": \"cnv_777\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Broadcast Typing Indicator",
                  content: "<p>Broadcasts an agent typing status event over WebSocket ActionCable to the customer and active agents.</p>"
                },
                de: {
                  title: "Schreibindikator übertragen",
                  content: "<p>Überträgt ein Tipp-Ereignis über WebSocket an Kunden und Agenten.</p>"
                },
                es: {
                  title: "Transmitir Indicador de Escritura",
                  content: "<p>Transmite un evento de escritura a través de WebSocket a los clientes y agentes.</p>"
                },
                fr: {
                  title: "Diffuser l'indicateur de saisie",
                  content: "<p>Diffuse un événement de saisie via WebSocket au client et aux agents.</p>"
                },
                "pt-BR": {
                  title: "Transmitir Indicador de Digitação",
                  content: "<p>Transmite um evento de digitação via WebSocket para o cliente e atendentes.</p>"
                },
                ar: {
                  title: "بث مؤشر الكتابة المباشر",
                  content: "<p>يبث حدث حالة كتابة الوكيل عبر WebSocket ActionCable إلى العميل والوكلاء الآخرين.</p>"
                },
                ko: {
                  title: "타이핑 인디케이터 전송",
                  content: "<p>상담원의 실시간 입력 상태를 웹소켓 ActionCable을 통해 고객 및 다른 상담원에게 전송합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

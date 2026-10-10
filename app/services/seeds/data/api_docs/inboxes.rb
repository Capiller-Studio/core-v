# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Inboxes
        def self.category
          {
            key: :inboxes,
            icon_key: "inbox",
            position: 5,
            api_reference: true,
            translations: {
              en: {
                name: "Inboxes",
                description: "Endpoints to list, inspect, configure, and manage collaborators on omnichannel inboxes (Email, Web Widget, WhatsApp, Facebook, Instagram, Contact Form, Custom channels)."
              },
              de: {
                name: "Postfächer",
                description: "Endpunkte zum Auflisten, Konfigurieren und Zuweisen von Mitarbeitern zu Omnichannel-Postfächern."
              },
              es: {
                name: "Bandejas de Entrada",
                description: "Puntos finales para listar, configurar y gestionar colaboradores en bandejas de entrada omnicanal."
              },
              fr: {
                name: "Boîtes de Réception",
                description: "Points de terminaison pour lister, configurer et gérer les collaborateurs des boîtes de réception omnicanales."
              },
              "pt-BR": {
                name: "Caixas de Entrada",
                description: "Endpoints para listar, configurar e gerenciar colaboradores em caixas de entrada multicanal."
              },
              ar: {
                name: "صناديق الوارد",
                description: "نقاط النهاية لسرد وتكوين وإدارة المتعاونين في صناديق الوارد متعددة القنوات."
              },
              ko: {
                name: "받은 편지함",
                description: "옴니채널 받은 편지함(이메일, 웹 위젯, WhatsApp, 인스타그램, 문의 폼, 커스텀 채널) 조회, 설정 및 담당자 관리 API입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :inboxes_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/inboxes",
                "api_parameters" => [
                  { "name" => "channel_type", "type" => "string", "description" => "Filter by channel type: email, web_widget, contact_form, facebook, instagram, whatsapp, custom", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-100, default: 50)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of inboxes",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"inb_901\",\n      \"name\": \"Support Email\",\n      \"display_name\": \"Customer Support\",\n      \"channel_type\": \"Channel::Email\",\n      \"channel_id\": \"chn_112\",\n      \"default_locale\": \"en\",\n      \"timezone\": \"UTC\",\n      \"status\": \"active\",\n      \"auto_assign\": true,\n      \"csat_survey_enabled\": true,\n      \"member_ids\": [\"usr_123\"],\n      \"team_ids\": [\"tm_456\"],\n      \"created_at\": \"2026-08-01T10:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Inboxes",
                  content: "<p>Returns all communication inboxes configured within the workspace account with optional channel type filtering.</p>"
                },
                de: {
                  title: "Postfächer auflisten",
                  content: "<p>Gibt alle im Arbeitsbereich konfigurierten Postfächer mit optionaler Kanaltyp-Filterung zurück.</p>"
                },
                es: {
                  title: "Listar Bandejas de Entrada",
                  content: "<p>Devuelve todas las bandejas de entrada configuradas en el espacio de trabajo con filtro opcional por canal.</p>"
                },
                fr: {
                  title: "Lister les boîtes de réception",
                  content: "<p>Renvoie toutes les boîtes de réception configurées dans l'espace de travail avec filtre de canal optionnel.</p>"
                },
                "pt-BR": {
                  title: "Listar Caixas de Entrada",
                  content: "<p>Retorna todas as caixas de entrada configuradas no espaço de trabalho com filtro opcional por canal.</p>"
                },
                ar: {
                  title: "عرض صناديق الوارد",
                  content: "<p>يعيد جميع صناديق الوارد التي تم تكوينها في مساحة العمل مع إمكانية التصفية بنوع القناة.</p>"
                },
                ko: {
                  title: "받은 편지함 목록 조회",
                  content: "<p>워크스페이스에 구성된 모든 소통 채널 받은 편지함 목록을 반환합니다. 채널 유형별 필터링이 가능합니다.</p>"
                }
              }
            },
            {
              key: :inboxes_get,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/inboxes/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Inbox UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Inbox details",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"inb_901\",\n    \"name\": \"Support Email\",\n    \"display_name\": \"Customer Support\",\n    \"channel_type\": \"Channel::Email\",\n    \"channel_id\": \"chn_112\",\n    \"default_locale\": \"en\",\n    \"timezone\": \"UTC\",\n    \"status\": \"active\",\n    \"auto_assign\": true,\n    \"csat_survey_enabled\": true,\n    \"member_ids\": [\"usr_123\"],\n    \"team_ids\": [\"tm_456\"],\n    \"created_at\": \"2026-08-01T10:00:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Inbox Details",
                  content: "<p>Retrieves specific configuration details for an inbox by its unique identifier.</p>"
                },
                de: {
                  title: "Postfachdetails abrufen",
                  content: "<p>Ruft Konfigurationsdetails für ein Postfach anhand seiner ID ab.</p>"
                },
                es: {
                  title: "Obtener Detalles de la Bandeja de Entrada",
                  content: "<p>Obtiene los detalles de configuración de una bandeja de entrada por su identificador.</p>"
                },
                fr: {
                  title: "Obtenir les détails de la boîte de réception",
                  content: "<p>Récupère les détails d'une boîte de réception par son identifiant unique.</p>"
                },
                "pt-BR": {
                  title: "Obter Detalhes da Caixa de Entrada",
                  content: "<p>Recupera os detalhes de uma caixa de entrada pelo seu identificador.</p>"
                },
                ar: {
                  title: "عرض تفاصيل صندوق الوارد",
                  content: "<p>يسترد تفاصيل التكوين لصندوق وارد معين بواسطة معرّفه الفريد.</p>"
                },
                ko: {
                  title: "받은 편지함 상세 조회",
                  content: "<p>고유 식별자(UUID)를 통해 특정 받은 편지함의 세부 설정 정보를 조회합니다.</p>"
                }
              }
            },
            {
              key: :inboxes_update,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/inboxes/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Inbox UUID", "required" => true },
                  { "name" => "name", "type" => "string", "description" => "Inbox internal name", "required" => false },
                  { "name" => "display_name", "type" => "string", "description" => "Public display name", "required" => false },
                  { "name" => "auto_assign", "type" => "boolean", "description" => "Enable automatic conversation assignment", "required" => false },
                  { "name" => "csat_survey_enabled", "type" => "boolean", "description" => "Enable CSAT survey upon resolution", "required" => false },
                  { "name" => "reopen_window_seconds", "type" => "integer", "description" => "Window in seconds before customer reply creates a new conversation", "required" => false },
                  { "name" => "member_ids", "type" => "array[string]", "description" => "List of agent user UUIDs to assign", "required" => false },
                  { "name" => "team_ids", "type" => "array[string]", "description" => "List of team UUIDs to assign", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Inbox updated",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"inb_901\",\n    \"name\": \"VIP Support Queue\",\n    \"auto_assign\": true,\n    \"csat_survey_enabled\": true\n  },\n  \"message\": \"Inbox updated successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Inbox Settings",
                  content: "<p>Updates routing settings, auto-assignment rules, CSAT survey status, and assigned members for an inbox.</p>"
                },
                de: {
                  title: "Postfacheinstellungen aktualisieren",
                  content: "<p>Aktualisiert Weiterleitungseinstellungen, automatische Zuweisung und zugewiesene Mitglieder.</p>"
                },
                es: {
                  title: "Actualizar Configuración de Bandeja",
                  content: "<p>Actualiza reglas de asignación, encuesta CSAT y miembros asignados a la bandeja de entrada.</p>"
                },
                fr: {
                  title: "Mettre à jour les paramètres de la boîte de réception",
                  content: "<p>Met à jour les paramètres de routage, l'assignation automatique et les membres assignés.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Configurações da Caixa de Entrada",
                  content: "<p>Atualiza regras de distribuição, pesquisa CSAT e membros atribuídos à caixa de entrada.</p>"
                },
                ar: {
                  title: "تحديث إعدادات صندوق الوارد",
                  content: "<p>يحدّث إعدادات التوجيه وقواعد التعيين التلقائي واستطلاع رضا العملاء والأعضاء المعينين.</p>"
                },
                ko: {
                  title: "받은 편지함 설정 수정",
                  content: "<p>받은 편지함의 자동 배정 규칙, CSAT 만족도 설문 활성화 및 담당 상담원/팀을 수정합니다.</p>"
                }
              }
            },
            {
              key: :inboxes_members_manage,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/inboxes/:id/members",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Inbox UUID", "required" => true },
                  { "name" => "user_ids", "type" => "array[string]", "description" => "List of agent user UUIDs to add to inbox", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Members assigned",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"inb_901\",\n    \"member_ids\": [\"usr_101\", \"usr_102\"]\n  },\n  \"message\": \"Members assigned successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Assign Members to Inbox",
                  content: "<p>Adds agent users to the inbox's authorized collaborator pool.</p>"
                },
                de: {
                  title: "Mitarbeiter zu Postfach zuweisen",
                  content: "<p>Weist Agenten als berechtigte Mitarbeiter dem Postfach zu.</p>"
                },
                es: {
                  title: "Asignar Miembros a la Bandeja",
                  content: "<p>Agrega agentes al grupo de colaboradores autorizados de la bandeja de entrada.</p>"
                },
                fr: {
                  title: "Assigner des membres à la boîte de réception",
                  content: "<p>Ajoute des agents au groupe de collaborateurs autorisés de la boîte de réception.</p>"
                },
                "pt-BR": {
                  title: "Atribuir Membros à Caixa de Entrada",
                  content: "<p>Adiciona agentes ao grupo de colaboradores da caixa de entrada.</p>"
                },
                ar: {
                  title: "تعيين أعضاء لصندوق الوارد",
                  content: "<p>يضيف وكلاء الدعم إلى مجموعة المتعاونين المصرح لهم لصندوق الوارد.</p>"
                },
                ko: {
                  title: "받은 편지함 담당 상담원 추가",
                  content: "<p>받은 편지함에 대화 열람 및 응대가 가능한 상담원들을 추가 배정합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

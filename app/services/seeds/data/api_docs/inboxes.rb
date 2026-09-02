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
                description: "Endpoints to list and inspect omnichannel inboxes (Email, Web Widget, WhatsApp, Facebook, Instagram, API channels)."
              },
              de: {
                name: "Postfächer",
                description: "Endpunkte zum Auflisten und Überprüfen von Omnichannel-Postfächern."
              },
              es: {
                name: "Bandejas de Entrada",
                description: "Puntos finales para listar e inspeccionar bandejas de entrada omnicanal."
              },
              fr: {
                name: "Boîtes de Réception",
                description: "Points de terminaison pour lister et inspecter les boîtes de réception omnicanales."
              },
              "pt-BR": {
                name: "Caixas de Entrada",
                description: "Endpoints para listar e consultar caixas de entrada multicanal."
              },
              ar: {
                name: "صناديق الوارد",
                description: "نقاط النهاية لسرد وفحص صناديق الوارد متعددة القنوات (البريد الإلكتروني، واتساب، فيسبوك، واجهة برمجة التطبيقات)."
              },
              ko: {
                name: "받은 편지함",
                description: "옴니채널 받은 편지함(이메일, 웹 위젯, WhatsApp, 인스타그램, API 채널) 목록 및 상세 조회 엔드포인트입니다."
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
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of inboxes",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"inb_901\",\n      \"name\": \"Support Email\",\n      \"channel_type\": \"Channel::Email\",\n      \"greeting_enabled\": false,\n      \"created_at\": \"2026-08-01T10:00:00Z\"\n    },\n    {\n      \"id\": \"inb_902\",\n      \"name\": \"Website Live Chat\",\n      \"channel_type\": \"Channel::WebWidget\",\n      \"greeting_enabled\": true,\n      \"greeting_message\": \"Hello! How can we help you today?\",\n      \"created_at\": \"2026-08-02T11:00:00Z\"\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Inboxes",
                  content: "<p>Returns all communication inboxes configured within the active workspace account.</p>"
                },
                de: {
                  title: "Postfächer auflisten",
                  content: "<p>Gibt alle im aktiven Arbeitsbereich konfigurierten Postfächer zurück.</p>"
                },
                es: {
                  title: "Listar Bandejas de Entrada",
                  content: "<p>Devuelve todas las bandejas de entrada configuradas en el espacio de trabajo.</p>"
                },
                fr: {
                  title: "Lister les boîtes de réception",
                  content: "<p>Renvoie toutes les boîtes de réception configurées dans l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Listar Caixas de Entrada",
                  content: "<p>Retorna todas as caixas de entrada configuradas no espaço de trabalho.</p>"
                },
                ar: {
                  title: "عرض صناديق الوارد",
                  content: "<p>يعيد جميع صناديق الوارد التي تم تكوينها في مساحة العمل النشطة.</p>"
                },
                ko: {
                  title: "받은 편지함 목록 조회",
                  content: "<p>활성 워크스페이스에 구성된 모든 소통 채널 받은 편지함 목록을 반환합니다.</p>"
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
                    "body" => "{\n  \"data\": {\n    \"id\": \"inb_901\",\n    \"name\": \"Support Email\",\n    \"channel_type\": \"Channel::Email\",\n    \"channel_id\": \"chn_112\",\n    \"created_at\": \"2026-08-01T10:00:00Z\"\n  }\n}"
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
            }
          ]
        end
      end
    end
  end
end

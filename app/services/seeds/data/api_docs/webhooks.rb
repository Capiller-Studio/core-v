# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Webhooks
        def self.category
          {
            key: :webhooks,
            icon_key: "radio",
            position: 16,
            api_reference: true,
            translations: {
              en: {
                name: "Webhooks",
                description: "Subscribe to real-time event webhooks for conversation lifecycle, customer creation, and message events."
              },
              de: {
                name: "Webhooks",
                description: "Abonnieren Sie Echtzeit-Events für Konversationen, Kunden und Nachrichten."
              },
              es: {
                name: "Webhooks",
                description: "Suscríbase a eventos en tiempo real para el ciclo de vida de conversaciones, clientes y mensajes."
              },
              fr: {
                name: "Webhooks",
                description: "Abonnez-vous aux événements en temps réel pour les conversations, clients et messages."
              },
              "pt-BR": {
                name: "Webhooks",
                description: "Assine eventos em tempo real para o ciclo de vida de conversas, clientes e mensagens."
              },
              ar: {
                name: "خطافات الويب (Webhooks)",
                description: "الاشتراك في أحداث النظام الفورية لدورة حياة المحادثات والعملاء والرسائل."
              },
              ko: {
                name: "웹훅 (Webhooks)",
                description: "대화 수신, 고객 생성, 메시지 이벤트 등 실시간 시스템 이벤트를 수신하는 웹훅 API입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :webhooks_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/webhooks",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of webhooks",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"int_501\",\n      \"name\": \"CRM Webhook\",\n      \"status\": \"active\",\n      \"url\": \"https://crm.example.com/events\",\n      \"events\": [\"conversation.created\", \"message.created\"],\n      \"inbox_ids\": []\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Webhooks",
                  content: "<p>Returns all outgoing webhook endpoints configured for the workspace account.</p>"
                },
                de: {
                  title: "Webhooks auflisten",
                  content: "<p>Gibt alle für das Konto konfigurierten ausgehenden Webhooks zurück.</p>"
                },
                es: {
                  title: "Listar Webhooks",
                  content: "<p>Devuelve todos los puntos finales de webhook salientes configurados.</p>"
                },
                fr: {
                  title: "Lister les webhooks",
                  content: "<p>Renvoie tous les webhooks sortants configurés pour le compte.</p>"
                },
                "pt-BR": {
                  title: "Listar Webhooks",
                  content: "<p>Retorna todos os webhooks de saída configurados para a conta.</p>"
                },
                ar: {
                  title: "عرض خطافات الويب",
                  content: "<p>يعيد جميع نقاط نهاية خطافات الويب الصادرة التي تم تكوينها للحساب.</p>"
                },
                ko: {
                  title: "웹훅 목록 조회",
                  content: "<p>계정에 구성된 모든 아웃바운드 이벤트 웹훅 엔드포인트 목록을 반환합니다.</p>"
                }
              }
            },
            {
              key: :webhooks_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/webhooks",
                "api_parameters" => [
                  { "name" => "url", "type" => "string", "description" => "Destination HTTPS endpoint URL", "required" => true },
                  { "name" => "name", "type" => "string", "description" => "Friendly name for the webhook", "required" => false },
                  { "name" => "events", "type" => "array[string]", "description" => "List of event types: conversation.created, message.created, customer.created", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Webhook created",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"int_502\",\n    \"name\": \"CRM Webhook\",\n    \"status\": \"active\",\n    \"url\": \"https://crm.example.com/events\",\n    \"events\": [\"conversation.created\"]\n  },\n  \"message\": \"Webhook created successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Webhook",
                  content: "<p>Registers a new webhook URL to receive signed event payloads.</p>"
                },
                de: {
                  title: "Webhook erstellen",
                  content: "<p>Registriert eine neue Webhook-URL zum Empfangen signierter Payloads.</p>"
                },
                es: {
                  title: "Crear Webhook",
                  content: "<p>Registra una nueva URL de webhook para recibir eventos firmados.</p>"
                },
                fr: {
                  title: "Créer un webhook",
                  content: "<p>Enregistre une nouvelle URL de webhook pour recevoir les charges utiles signées.</p>"
                },
                "pt-BR": {
                  title: "Criar Webhook",
                  content: "<p>Registra uma nova URL de webhook para receber payloads assinados.</p>"
                },
                ar: {
                  title: "إنشاء خطاف ويب",
                  content: "<p>يسجل عنوان URL جديدًا لتلقي حمولات الأحداث الموقعة رقميًا.</p>"
                },
                ko: {
                  title: "웹훅 등록",
                  content: "<p>서명된 실시간 이벤트 페이로드를 수신할 새로운 HTTPS 웹훅 엔드포인트를 등록합니다.</p>"
                }
              }
            },
            {
              key: :webhooks_update,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/webhooks/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Webhook UUID", "required" => true },
                  { "name" => "name", "type" => "string", "description" => "Updated friendly name", "required" => false },
                  { "name" => "url", "type" => "string", "description" => "Updated destination URL", "required" => false },
                  { "name" => "events", "type" => "array[string]", "description" => "Updated subscribed events list", "required" => false },
                  { "name" => "status", "type" => "string", "description" => "'active' or 'disabled'", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Webhook updated",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"int_502\",\n    \"name\": \"Analytics Webhook\",\n    \"status\": \"active\"\n  },\n  \"message\": \"Webhook updated successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Webhook",
                  content: "<p>Updates destination URL, active status, or subscribed event types for an existing webhook.</p>"
                },
                de: {
                  title: "Webhook aktualisieren",
                  content: "<p>Aktualisiert Ziel-URL, Status oder abonnierte Events.</p>"
                },
                es: {
                  title: "Actualizar Webhook",
                  content: "<p>Actualiza URL de destino, estado o eventos suscritos.</p>"
                },
                fr: {
                  title: "Mettre à jour le webhook",
                  content: "<p>Met à jour l'URL, le statut ou les événements souscrits.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Webhook",
                  content: "<p>Atualiza a URL, status ou eventos assinados do webhook.</p>"
                },
                ar: {
                  title: "تحديث خطاف الويب",
                  content: "<p>يحدّث عنوان URL للوجهة أو الحالة النشطة أو الأحداث المشترك فيها.</p>"
                },
                ko: {
                  title: "웹훅 수정",
                  content: "<p>웹훅의 대상 URL, 활성화 상태 또는 구독 이벤트 목록을 변경합니다.</p>"
                }
              }
            },
            {
              key: :webhooks_delete,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/webhooks/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Webhook UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Webhook deleted",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Webhook deleted successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Delete Webhook",
                  content: "<p>Removes a webhook integration from the workspace.</p>"
                },
                de: {
                  title: "Webhook löschen",
                  content: "<p>Entfernt eine Webhook-Integration aus dem Arbeitsbereich.</p>"
                },
                es: {
                  title: "Eliminar Webhook",
                  content: "<p>Elimina una integración de webhook del espacio de trabajo.</p>"
                },
                fr: {
                  title: "Supprimer le webhook",
                  content: "<p>Supprime une intégration de webhook de l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Excluir Webhook",
                  content: "<p>Remove uma integração de webhook do espaço de trabalho.</p>"
                },
                ar: {
                  title: "حذف خطاف الويب",
                  content: "<p>يحذف تكامل خطاف الويب من مساحة العمل.</p>"
                },
                ko: {
                  title: "웹훅 삭제",
                  content: "<p>등록된 웹훅 연동을 완전히 삭제합니다.</p>"
                }
              }
            },
            {
              key: :webhooks_test,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/webhooks/:id/test",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Webhook UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Test ping dispatched",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"event\": \"test.ping\",\n    \"webhook_id\": \"int_502\",\n    \"url\": \"https://crm.example.com/events\",\n    \"dispatched_at\": \"2026-10-10T10:00:00Z\"\n  },\n  \"message\": \"Test ping dispatched successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Send Test Ping",
                  content: "<p>Immediately delivers a signed <code>test.ping</code> event to verify server connectivity and signature verification.</p>"
                },
                de: {
                  title: "Test-Ping senden",
                  content: "<p>Sendet sofort ein signiertes <code>test.ping</code>-Event zur Überprüfung der Verbindung.</p>"
                },
                es: {
                  title: "Enviar Ping de Prueba",
                  content: "<p>Envía inmediatamente un evento <code>test.ping</code> firmado para verificar la conectividad.</p>"
                },
                fr: {
                  title: "Envoyer un ping de test",
                  content: "<p>Envoie immédiatement un événement <code>test.ping</code> signé pour tester la connectivité.</p>"
                },
                "pt-BR": {
                  title: "Enviar Ping de Teste",
                  content: "<p>Dispara imediatamente um evento <code>test.ping</code> assinado para testar a conectividade.</p>"
                },
                ar: {
                  title: "إرسال اختبار الاتصال (Ping)",
                  content: "<p>يرسل فورًا حدث <code>test.ping</code> موقّعًا للتحقق من اتصال الخادم والتحقق من التوقيع.</p>"
                },
                ko: {
                  title: "테스트 핑 전송",
                  content: "<p>서버 수신 상태 및 서명 검증을 즉시 테스트할 수 있도록 서명된 <code>test.ping</code> 이벤트를 전송합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Messages
        def self.category
          {
            key: :messages,
            icon_key: "message-circle",
            position: 8,
            api_reference: true,
            translations: {
              en: {
                name: "Messages",
                description: "Endpoints to send omnichannel customer replies, post private team notes, list message history, and perform AI translations."
              },
              de: {
                name: "Nachrichten",
                description: "Endpunkte zum Senden von Antworten, internen Notizen, Abrufen des Verlaufs und Übersetzen."
              },
              es: {
                name: "Mensajes",
                description: "Puntos finales para enviar respuestas, notas privadas internas, listar historial y traducir."
              },
              fr: {
                name: "Messages",
                description: "Points de terminaison pour envoyer des réponses, des notes internes privées et traduire des messages."
              },
              "pt-BR": {
                name: "Mensagens",
                description: "Endpoints para enviar respostas, notas internas privadas, consultar histórico e traduzir mensagens."
              },
              ar: {
                name: "الرسائل",
                description: "نقاط النهاية لإرسال الردود للعملاء، ونشر الملاحظات الداخلية الخاصة، واسترجاع السجل والترجمة الفورية."
              },
              ko: {
                name: "메시지 관리",
                description: "고객 답변 발송, 내부 비공개 메모 작성, 대화 메시지 내역 조회 및 AI 다국어 번역 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :messages_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/conversations/:conversation_id/messages",
                "api_parameters" => [
                  { "name" => "conversation_id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-100, default: 50)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of messages",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"msg_001\",\n      \"content\": \"Hi, I need help with my billing invoice.\",\n      \"visibility\": \"global\",\n      \"sender\": {\n        \"id\": \"cst_101\",\n        \"name\": \"Alice Johnson\",\n        \"type\": \"Customer\"\n      },\n      \"attachments\": [],\n      \"created_at\": \"2026-09-02T13:00:00Z\"\n    },\n    {\n      \"id\": \"msg_002\",\n      \"content\": \"Checking user subscription status...\",\n      \"visibility\": \"personal\",\n      \"sender\": {\n        \"id\": \"usr_888\",\n        \"name\": \"Sarah Connor\",\n        \"type\": \"User\"\n      },\n      \"created_at\": \"2026-09-02T13:02:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 2\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Messages in Conversation",
                  content: "<p>Returns the chronological message history for a conversation including public customer messages and internal team notes.</p>"
                },
                de: {
                  title: "Nachrichten in Konversation auflisten",
                  content: "<p>Gibt den chronologischen Nachrichtenverlauf einer Konversation zurück.</p>"
                },
                es: {
                  title: "Listar Mensajes en la Conversación",
                  content: "<p>Devuelve el historial cronológico de mensajes de una conversación.</p>"
                },
                fr: {
                  title: "Lister les messages de la conversation",
                  content: "<p>Renvoie l'historique chronologique des messages d'une conversation.</p>"
                },
                "pt-BR": {
                  title: "Listar Mensagens na Conversa",
                  content: "<p>Retorna o histórico cronológico de mensagens de uma conversa.</p>"
                },
                ar: {
                  title: "عرض الرسائل في المحادثة",
                  content: "<p>يعيد السجل الزمني لرسائل المحادثة بما في ذلك رسائل العملاء والملاحظات الداخلية.</p>"
                },
                ko: {
                  title: "대화 내 메시지 목록 조회",
                  content: "<p>특정 대화의 전체 메시지 내역(고객 메시지 및 내부 비공개 메모)을 시간순으로 반환합니다.</p>"
                }
              }
            },
            {
              key: :messages_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:conversation_id/messages",
                "api_parameters" => [
                  { "name" => "conversation_id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "content", "type" => "string", "description" => "Message text or HTML (max 50,000 chars)", "required" => false },
                  { "name" => "private", "type" => "boolean", "description" => "True for internal private notes (not sent to customer)", "required" => false },
                  { "name" => "attachment_ids", "type" => "array[string]", "description" => "Array of uploaded attachment UUIDs to attach", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Message created",
                    "body" => "{\n  \"data\": {\n    \"id\": \"msg_003\",\n    \"content\": \"Hello Alice! I have reviewed your invoice and refunded the difference.\",\n    \"visibility\": \"global\",\n    \"sender\": {\n      \"id\": \"usr_888\",\n      \"name\": \"Sarah Connor\"\n    },\n    \"created_at\": \"2026-09-02T13:05:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Send Message / Private Note",
                  content: "<p>Sends a reply to the customer through the active channel (Email, WhatsApp, Chat, etc.) or records a private internal note for teammates.</p>"
                },
                de: {
                  title: "Nachricht / Private Notiz senden",
                  content: "<p>Sendet eine Antwort an den Kunden über den aktiven Kanal oder speichert eine interne Notiz.</p>"
                },
                es: {
                  title: "Enviar Mensaje / Nota Privada",
                  content: "<p>Envía una respuesta al cliente a través del canal activo o registra una nota privada.</p>"
                },
                fr: {
                  title: "Envoyer un message / Note privée",
                  content: "<p>Envoie une réponse au client ou enregistre une note interne privée.</p>"
                },
                "pt-BR": {
                  title: "Enviar Mensagem / Nota Privada",
                  content: "<p>Envia uma resposta ao cliente ou registra uma nota interna privada.</p>"
                },
                ar: {
                  title: "إرسال رسالة / ملاحظة خاصة",
                  content: "<p>يرسل ردًا للعميل عبر القناة النشطة (البريد الإلكتروني، واتساب، الدردشة) أو يسجل ملاحظة داخلية خاصة للفريق.</p>"
                },
                ko: {
                  title: "메시지 / 비공개 메모 발송",
                  content: "<p>활성 채널(이메일, WhatsApp, 실시간 채팅 등)을 통해 고객에게 답변을 전송하거나 팀원 전용 비공개 메모를 등록합니다.</p>"
                }
              }
            },
            {
              key: :messages_translate,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/conversations/:conversation_id/messages/:id/translate",
                "api_parameters" => [
                  { "name" => "conversation_id", "type" => "string", "description" => "Conversation UUID", "required" => true },
                  { "name" => "id", "type" => "string", "description" => "Message UUID", "required" => true },
                  { "name" => "target_locale", "type" => "string", "description" => "Target language code: 'en', 'de', 'es', 'fr', 'pt-BR', 'ar', 'ko'", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Translation result",
                    "body" => "{\n  \"data\": {\n    \"message_id\": \"msg_001\",\n    \"original_content\": \"Bonjour, j'ai besoin d'aide.\",\n    \"translated_content\": \"Hello, I need help.\",\n    \"target_locale\": \"en\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Translate Message Content",
                  content: "<p>Translates an incoming or outgoing message into any of the 7 supported languages using AI translation engine.</p>"
                },
                de: {
                  title: "Nachrichteninhalt übersetzen",
                  content: "<p>Übersetzt den Inhalt einer Nachricht mithilfe der KI-Übersetzungs-Engine.</p>"
                },
                es: {
                  title: "Traducir Contenido del Mensaje",
                  content: "<p>Traduce el contenido de un mensaje a cualquiera de los idiomas admitidos.</p>"
                },
                fr: {
                  title: "Traduire le contenu du message",
                  content: "<p>Traduit le contenu d'un message dans l'une des 7 langues prises en charge.</p>"
                },
                "pt-BR": {
                  title: "Traduzir Conteúdo da Mensagem",
                  content: "<p>Traduz o conteúdo de uma mensagem para qualquer um dos 7 idiomas suportados.</p>"
                },
                ar: {
                  title: "ترجمة محتوى الرسالة",
                  content: "<p>يترجم محتوى الرسالة إلى أي من اللغات السبع المدعومة باستخدام محرك الترجمة المدعوم بالذكاء الاصطناعي.</p>"
                },
                ko: {
                  title: "메시지 내용 AI 번역",
                  content: "<p>수신 또는 발신된 메시지 본문을 7개 지원 언어 중 하나로 실시간 AI 번역합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

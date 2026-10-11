# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module MobileSdk
        def self.category
          {
            key: :mobile_sdk,
            icon_key: "smartphone",
            position: 5,
            api_reference: true,
            translations: {
              en: {
                name: "Mobile SDK API",
                description: "REST endpoints powering native mobile apps (iOS & Android) via Flutter SDK, supporting guest & verified identity sessions, messaging, direct uploads, and push token registration."
              },
              de: {
                name: "Mobile SDK API",
                description: "REST-Endpunkte für native mobile Apps (iOS & Android) über das Flutter-SDK mit Unterstützung für Gast- und verifizierte Sitzungen, Chat, Uploads und Push-Benachrichtigungen."
              },
              es: {
                name: "API de SDK Móvil",
                description: "Puntos finales REST para aplicaciones móviles nativas (iOS y Android) mediante Flutter SDK, con soporte de sesiones anónimas y verificadas, mensajería y notificaciones push."
              },
              fr: {
                name: "API SDK Mobile",
                description: "Points de terminaison REST pour applications mobiles natives (iOS et Android) via le SDK Flutter, prenant en charge les sessions invités et vérifiées, les messages et les notifications push."
              },
              "pt-BR": {
                name: "API do SDK Mobile",
                description: "Endpoints REST para aplicativos móveis nativos (iOS e Android) via Flutter SDK, com suporte para sessões de convidados e verificadas, mensagens e notificações push."
              },
              ar: {
                name: "واجهة برمجة تطبيقات SDK للهواتف",
                description: "نقاط نهاية REST لتطبيقات الأجهزة المحمولة الأصلية (iOS و Android) عبر Flutter SDK، مع دعم جلسات الضيوف والهويات الموثقة والرسائل والإشعارات."
              },
              ko: {
                name: "모바일 SDK API",
                description: "Flutter SDK를 통한 네이티브 모바일 앱(iOS & Android) 연동 REST 엔드포인트입니다. 게스트 및 검증된 세션, 실시간 메시지, 첨부파일 업로드, 푸시 토큰 등록을 지원합니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :sdk_config_get,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/config",
                "api_parameters" => [
                  { "name" => "X-Mobile-Widget-Identifier", "type" => "string", "description" => "Mobile widget channel public identifier token", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Widget configuration retrieved successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"identifier\": \"mws_9b8417532a\",\n    \"name\": \"Mobile In-App Help\",\n    \"color\": \"#6366F1\",\n    \"welcome_title\": \"Hi there! How can we help?\",\n    \"welcome_tagline\": \"Our support team typically replies in under 5 minutes.\",\n    \"reply_time\": \"in_a_few_minutes\",\n    \"locale\": \"en\",\n    \"attachments_enabled\": true,\n    \"max_attachment_size_mb\": 25,\n    \"allowed_attachment_types\": [\"image/*\", \"application/pdf\"],\n    \"identity_verification_required\": false\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get SDK Configuration",
                  content: "<p>Retrieves branding colors, localized welcome copy, attachments limits, and security configuration for the mobile widget channel.</p>"
                },
                de: {
                  title: "SDK-Konfiguration abrufen",
                  content: "<p>Ruft Designfarben, lokalisierte Begrüßungstexte, Anhangslimits und Sicherheitseinstellungen für den mobilen Kanal ab.</p>"
                },
                es: {
                  title: "Obtener Configuración del SDK",
                  content: "<p>Obtiene los colores de marca, textos de bienvenida localizados, límites de archivos adjuntos y configuración de seguridad.</p>"
                },
                fr: {
                  title: "Obtenir la configuration du SDK",
                  content: "<p>Récupère les couleurs, textes d'accueil localisés, limites de pièces jointes et paramètres de sécurité du canal mobile.</p>"
                },
                "pt-BR": {
                  title: "Obter Configuração do SDK",
                  content: "<p>Retorna as cores da marca, textos de boas-vindas localizados, limites de anexos e configurações de segurança.</p>"
                },
                ar: {
                  title: "الحصول على إعدادات SDK",
                  content: "<p>استرداد ألوان الهوية البصرية، ونصوص الترحيب المترجمة، وحدود المرفقات، وإعدادات الأمان لقناة التطبيق.</p>"
                },
                ko: {
                  title: "SDK 설정 조회",
                  content: "<p>모바일 위젯 채널의 브랜드 컬러, 환영 문구, 첨부파일 제한 및 신원 검증 필수 여부 설정을 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_session_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/sdk/session",
                "api_parameters" => [
                  { "name" => "customer_token", "type" => "string", "description" => "Persistent unique device or user identifier generated by the client", "required" => true },
                  { "name" => "email", "type" => "string", "description" => "Customer email address", "required" => false },
                  { "name" => "name", "type" => "string", "description" => "Customer full name", "required" => false },
                  { "name" => "phone_number", "type" => "string", "description" => "E.164 formatted phone number", "required" => false },
                  { "name" => "avatar_url", "type" => "string", "description" => "Customer avatar URL", "required" => false },
                  { "name" => "custom_attributes", "type" => "object", "description" => "Key-value custom attributes (e.g. plan, app_version)", "required" => false },
                  { "name" => "identity_token", "type" => "string", "description" => "JWT signed with widget shared secret (HS256)", "required" => false },
                  { "name" => "identity_hash", "type" => "string", "description" => "HMAC-SHA256 hex digest of customer email/token", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Session created or resumed",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"session_token\": \"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\",\n    \"expires_at\": \"2026-11-10T18:00:00Z\",\n    \"customer\": {\n      \"id\": 4819,\n      \"name\": \"Alex Rivera\",\n      \"email\": \"alex@company.com\",\n      \"phone_number\": \"+14155552671\",\n      \"avatar_url\": null,\n      \"custom_attributes\": {\"plan\": \"enterprise\", \"tier\": 2}\n    },\n    \"unread_count\": 0\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Authenticate / Start Session",
                  content: "<p>Initializes a mobile session. Supports anonymous guest users with local device tokens or verified registered users using JWT/HMAC identity signatures.</p>"
                },
                de: {
                  title: "Sitzung starten / Authentifizieren",
                  content: "<p>Initialisiert eine mobile Sitzung für Gastbenutzer oder verifizierte Kunden mit JWT/HMAC-Identitätsnachweis.</p>"
                },
                es: {
                  title: "Autenticar / Iniciar Sesión",
                  content: "<p>Inicializa una sesión móvil. Permite usuarios invitados o usuarios registrados verificados con JWT o HMAC.</p>"
                },
                fr: {
                  title: "Authentifier / Démarrer une session",
                  content: "<p>Initialise une session mobile. Prend en charge les invités anonymes et les utilisateurs vérifiés avec signature JWT/HMAC.</p>"
                },
                "pt-BR": {
                  title: "Autenticar / Iniciar Sessão",
                  content: "<p>Inicializa uma sessão móvel. Suporta usuários anônimos ou clientes verificados com assinatura JWT/HMAC.</p>"
                },
                ar: {
                  title: "المصادقة / بدء الجلسة",
                  content: "<p>تهيئة جلسة مستخدم للهاتف المحمول للضيوف أو المستخدمين الموثقين عبر توقيعات JWT أو HMAC.</p>"
                },
                ko: {
                  title: "세션 생성 및 사용자 인증",
                  content: "<p>모바일 세션을 시작합니다. 게스트 세션 및 JWT/HMAC 서명을 통한 인증된 사용자 식별을 지원합니다.</p>"
                }
              }
            },
            {
              key: :sdk_conversations_list,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/conversations",
                "api_parameters" => [
                  { "name" => "page", "type" => "integer", "description" => "Page number (defaults to 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Items per page (max 50, default 20)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Customer conversations list",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": 1082,\n      \"status\": \"open\",\n      \"unread_count\": 1,\n      \"created_at\": \"2026-10-10T17:40:00Z\",\n      \"last_activity_at\": \"2026-10-10T17:42:00Z\",\n      \"last_message\": {\n        \"id\": 84920,\n        \"content\": \"Hello Alex! Let me look into that for you.\",\n        \"sender_type\": \"user\",\n        \"created_at\": \"2026-10-10T17:42:00Z\"\n      }\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Conversations",
                  content: "<p>Returns all conversations belonging to the authenticated mobile customer across this channel.</p>"
                },
                de: {
                  title: "Unterhaltungen auflisten",
                  content: "<p>Gibt alle Unterhaltungen des authentifizierten mobilen Kunden in diesem Kanal zurück.</p>"
                },
                es: {
                  title: "Listar Conversaciones",
                  content: "<p>Devuelve todas las conversaciones del cliente móvil autenticado en este canal.</p>"
                },
                fr: {
                  title: "Lister les conversations",
                  content: "<p>Renvoie toutes les conversations appartenant au client mobile authentifié sur ce canal.</p>"
                },
                "pt-BR": {
                  title: "Listar Conversas",
                  content: "<p>Retorna todas as conversas do cliente autenticado neste canal de aplicativo.</p>"
                },
                ar: {
                  title: "قائمة المحادثات",
                  content: "<p>استرجاع جميع المحادثات الخاصة بالعميل المصادق عليه في قناة الهاتف هذه.</p>"
                },
                ko: {
                  title: "대화 목록 조회",
                  content: "<p>인증된 모바일 고객의 전체 상담 대화 목록을 페이지네이션하여 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_conversations_create,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/sdk/conversations",
                "api_parameters" => [
                  { "name" => "content", "type" => "string", "description" => "Initial message text body", "required" => true },
                  { "name" => "echo_id", "type" => "string", "description" => "Client-side unique message ID for optimistic UI rendering", "required" => false },
                  { "name" => "attachment_signed_ids", "type" => "array", "description" => "List of signed blob IDs from direct uploads", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "New conversation created with first message",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"conversation\": {\n      \"id\": 1083,\n      \"status\": \"open\",\n      \"created_at\": \"2026-10-10T18:00:00Z\"\n    },\n    \"message\": {\n      \"id\": 84925,\n      \"content\": \"I have a question about billing.\",\n      \"sender_type\": \"customer\",\n      \"echo_id\": \"local-msg-4912\",\n      \"created_at\": \"2026-10-10T18:00:00Z\"\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Conversation",
                  content: "<p>Starts a new support conversation and dispatches the initial message to available agents.</p>"
                },
                de: {
                  title: "Unterhaltung erstellen",
                  content: "<p>Startet eine neue Support-Unterhaltung und leitet die erste Nachricht an verfügbare Agenten weiter.</p>"
                },
                es: {
                  title: "Crear Conversación",
                  content: "<p>Inicia una nueva conversación de soporte y envía el mensaje inicial a los agentes.</p>"
                },
                fr: {
                  title: "Créer une conversation",
                  content: "<p>Démarre une nouvelle conversation d'assistance et transmet le premier message aux agents disponibles.</p>"
                },
                "pt-BR": {
                  title: "Criar Conversa",
                  content: "<p>Inicia uma nova conversa de suporte e entrega a mensagem inicial aos agentes disponíveis.</p>"
                },
                ar: {
                  title: "إنشاء محادثة جديدة",
                  content: "<p>بدء محادثة دعم فني جديدة وإرسال الرسالة الأولى إلى الوكلاء المتاحين.</p>"
                },
                ko: {
                  title: "새 대화 시작",
                  content: "<p>새로운 지원 요청 대화를 시작하고 첫 메시지를 상담원 팀에게 전달합니다.</p>"
                }
              }
            },
            {
              key: :sdk_messages_list,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/conversations/:id/messages",
                "api_parameters" => [
                  { "name" => "id", "type" => "integer", "description" => "Conversation ID", "required" => true },
                  { "name" => "before", "type" => "integer", "description" => "Cursor: fetch messages before this message ID", "required" => false },
                  { "name" => "after", "type" => "integer", "description" => "Cursor: fetch messages after this message ID", "required" => false },
                  { "name" => "limit", "type" => "integer", "description" => "Number of messages (default 25, max 100)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of messages",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": 84920,\n      \"content\": \"Hello, how may I assist you today?\",\n      \"sender_type\": \"user\",\n      \"sender\": {\n        \"id\": \"usr_102\",\n        \"name\": \"Sarah Connor\",\n        \"avatar_url\": \"https://cdn.deskbolic.com/avatars/102.png\"\n      },\n      \"attachments\": [],\n      \"created_at\": \"2026-10-10T17:42:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"has_more\": false\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Conversation Messages",
                  content: "<p>Fetches message history for a conversation using efficient cursor pagination. Only public messages (not private notes) are returned.</p>"
                },
                de: {
                  title: "Nachrichten der Unterhaltung abrufen",
                  content: "<p>Ruft den Nachrichtenverlauf einer Unterhaltung mit Cursor-Paginierung ab. Es werden ausschließlich öffentliche Nachrichten zurückgegeben.</p>"
                },
                es: {
                  title: "Listar Mensajes de la Conversación",
                  content: "<p>Obtiene el historial de mensajes mediante paginación por cursor. Solo se devuelven mensajes públicos.</p>"
                },
                fr: {
                  title: "Lister les messages d'une conversation",
                  content: "<p>Récupère l'historique des messages à l'aide d'une pagination par curseur. Seuls les messages publics sont renvoyés.</p>"
                },
                "pt-BR": {
                  title: "Listar Mensagens da Conversa",
                  content: "<p>Retorna o histórico de mensagens da conversa utilizando paginação por cursor. Notas internas nunca são expostas.</p>"
                },
                ar: {
                  title: "قائمة رسائل المحادثة",
                  content: "<p>استرجاع سجل الرسائل باستخدام مؤشرات الصفحات. يتم إرجاع الرسائل العامة فقط دون الملاحظات الداخلية.</p>"
                },
                ko: {
                  title: "대화 메시지 내역 조회",
                  content: "<p>커서 기반 페이지네이션으로 대화의 이전 메시지 기록을 조회합니다. 내부 상담원 메모는 보안상 제외됩니다.</p>"
                }
              }
            },
            {
              key: :sdk_messages_create,
              article_type: :api_endpoint,
              position: 6,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/sdk/conversations/:id/messages",
                "api_parameters" => [
                  { "name" => "id", "type" => "integer", "description" => "Conversation ID", "required" => true },
                  { "name" => "content", "type" => "string", "description" => "Message content text", "required" => true },
                  { "name" => "echo_id", "type" => "string", "description" => "Client optimistic identifier", "required" => false },
                  { "name" => "attachment_signed_ids", "type" => "array", "description" => "Direct upload signed blob IDs", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Message posted successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": 84931,\n    \"content\": \"Here is a screenshot of the issue.\",\n    \"sender_type\": \"customer\",\n    \"echo_id\": \"local-109\",\n    \"attachments\": [\n      {\n        \"id\": 912,\n        \"filename\": \"screenshot.png\",\n        \"content_type\": \"image/png\",\n        \"byte_size\": 124800,\n        \"url\": \"https://storage.deskbolic.com/blobs/...\"\n      }\n    ],\n    \"created_at\": \"2026-10-10T18:05:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Send Message",
                  content: "<p>Sends a new reply message in an existing conversation, broadcasting in real-time over WebSocket and notifying assigned agents.</p>"
                },
                de: {
                  title: "Nachricht senden",
                  content: "<p>Sendet eine Antwort in einer bestehenden Unterhaltung mit Echtzeitübertragung per WebSocket.</p>"
                },
                es: {
                  title: "Enviar Mensaje",
                  content: "<p>Envía un nuevo mensaje de respuesta en una conversación existente con transmisión en tiempo real vía WebSocket.</p>"
                },
                fr: {
                  title: "Envoyer un message",
                  content: "<p>Envoie une nouvelle réponse dans une conversation existante avec diffusion en direct par WebSocket.</p>"
                },
                "pt-BR": {
                  title: "Enviar Mensagem",
                  content: "<p>Envia uma nova mensagem na conversa, transmitindo em tempo real via WebSocket e notificando os agentes.</p>"
                },
                ar: {
                  title: "إرسال رسالة",
                  content: "<p>إرسال رسالة رد جديدة في محادثة قائمة مع البث الفوري عبر WebSocket وإشعار الوكلاء.</p>"
                },
                ko: {
                  title: "메시지 전송",
                  content: "<p>기존 대화에 고객 메시지를 전송하고 웹소켓을 통해 실시간으로 브로드캐스트합니다.</p>"
                }
              }
            },
            {
              key: :sdk_devices_create,
              article_type: :api_endpoint,
              position: 7,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/sdk/devices",
                "api_parameters" => [
                  { "name" => "token", "type" => "string", "description" => "Device push notification token (APNs device token or FCM registration token)", "required" => true },
                  { "name" => "platform", "type" => "string", "description" => "Device OS platform: 'ios' or 'android'", "required" => true },
                  { "name" => "device_id", "type" => "string", "description" => "Unique hardware/vendor identifier (e.g. identifierForVendor)", "required" => false },
                  { "name" => "app_version", "type" => "string", "description" => "Mobile app semantic version string (e.g. '1.4.0')", "required" => false },
                  { "name" => "os_version", "type" => "string", "description" => "Operating system version (e.g. 'iOS 18.1')", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Device token registered",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": 341,\n    \"platform\": \"ios\",\n    \"device_id\": \"9B3A2C-14F9-410E\",\n    \"created_at\": \"2026-10-10T18:10:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Register Push Device",
                  content: "<p>Registers the mobile device for background push notifications when agents reply to the customer's conversations.</p>"
                },
                de: {
                  title: "Push-Gerät registrieren",
                  content: "<p>Registriert das Mobilgerät für Push-Benachrichtigungen im Hintergrund bei Antworten von Support-Mitarbeitern.</p>"
                },
                es: {
                  title: "Registrar Dispositivo Push",
                  content: "<p>Registra el dispositivo móvil para recibir notificaciones push en segundo plano cuando los agentes respondan.</p>"
                },
                fr: {
                  title: "Enregistrer l'appareil pour les notifications push",
                  content: "<p>Enregistre l'appareil mobile pour recevoir des notifications push en arrière-plan lorsque les agents répondent.</p>"
                },
                "pt-BR": {
                  title: "Registrar Dispositivo para Push",
                  content: "<p>Registra o dispositivo móvel para receber notificações push quando agentes responderem às conversas.</p>"
                },
                ar: {
                  title: "تسجيل جهاز للإشعارات الفورية",
                  content: "<p>تسجيل الجهاز المحمول لاستلام الإشعارات الفورية في الخلفية عند رد وكلاء الدعم الفني.</p>"
                },
                ko: {
                  title: "푸시 알림 기기 등록",
                  content: "<p>상담원의 답변 발생 시 백그라운드 푸시 알림을 수신할 수 있도록 APNs 또는 FCM 기기 토큰을 등록합니다.</p>"
                }
              }
            },
            {
              key: :sdk_devices_delete,
              article_type: :api_endpoint,
              position: 8,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/sdk/devices/:token",
                "api_parameters" => [
                  { "name" => "token", "type" => "string", "description" => "Push token to unregister", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Device unregistered successfully",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Device unregistered successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Unregister Push Device",
                  content: "<p>Unregisters a device push token when the user logs out or disables notifications.</p>"
                },
                de: {
                  title: "Push-Gerät abmelden",
                  content: "<p>Meldet ein Push-Token ab, wenn sich der Benutzer abmeldet oder Benachrichtigungen deaktiviert.</p>"
                },
                es: {
                  title: "Desregistrar Dispositivo Push",
                  content: "<p>Elimina el registro de un token push cuando el usuario cierra sesión o desactiva las notificaciones.</p>"
                },
                fr: {
                  title: "Désinscrire l'appareil push",
                  content: "<p>Désinscrit un jeton push lorsque l'utilisateur se déconnecte ou désactive les notifications.</p>"
                },
                "pt-BR": {
                  title: "Desregistrar Dispositivo Push",
                  content: "<p>Remove o token de notificação quando o usuário realiza logout ou desativa notificações.</p>"
                },
                ar: {
                  title: "إلغاء تسجيل جهاز الإشعارات",
                  content: "<p>إلغاء تسجيل رمز إشعارات الجهاز عند تسجيل خروج المستخدم أو تعطيل الإشعارات.</p>"
                },
                ko: {
                  title: "푸시 알림 기기 해제",
                  content: "<p>사용자 로그아웃 또는 알림 비활성화 시 기기 푸시 토큰 등록을 해제합니다.</p>"
                }
              }
            },
            {
              key: :sdk_unread_count_get,
              article_type: :api_endpoint,
              position: 9,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/unread_count",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Total unread message count",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"unread_count\": 3\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Unread Count",
                  content: "<p>Returns the total number of unread messages across all active conversations for badge counter display on mobile tabs or app icons.</p>"
                },
                de: {
                  title: "Ungelesene Nachrichten zählen",
                  content: "<p>Gibt die Gesamtzahl der ungelesenen Nachrichten für Badge-Zähler in der App zurück.</p>"
                },
                es: {
                  title: "Obtener Contador de No Leídos",
                  content: "<p>Devuelve el número total de mensajes no leídos para contadores y distintivos visuales en la aplicación móvil.</p>"
                },
                fr: {
                  title: "Obtenir le nombre de non lus",
                  content: "<p>Renvoie le nombre total de messages non lus pour l'affichage des badges sur les icônes d'application.</p>"
                },
                "pt-BR": {
                  title: "Obter Total de Não Lidas",
                  content: "<p>Retorna o número total de mensagens não lidas para exibição em badges de abas ou ícones do aplicativo.</p>"
                },
                ar: {
                  title: "الحصول على عدد الرسائل غير المقروءة",
                  content: "<p>استرجاع إجمالي عدد الرسائل غير المقروءة لعرضها في شارات التنبيهات على أيقونة التطبيق.</p>"
                },
                ko: {
                  title: "읽지 않은 메시지 수 조회",
                  content: "<p>앱 아이콘 배지 및 알림 탭에 표시할 전체 미확인 메시지 개수를 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_forms_pre_chat,
              article_type: :api_endpoint,
              position: 10,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/forms/pre_chat",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "description" => "Mobile widget channel public identifier", "required" => true },
                  { "name" => "locale", "type" => "string", "description" => "Requested language locale (e.g. en, es, fr)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Pre-chat form schema retrieved successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"enabled\": true,\n    \"title\": \"Start a Conversation\",\n    \"subtitle\": \"Please introduce yourself to start chatting with our team\",\n    \"submit_button_text\": \"Start Chat\",\n    \"locale\": \"en\",\n    \"fields\": [\n      {\n        \"key\": \"name\",\n        \"label\": \"Full Name\",\n        \"placeholder\": \"Enter your full name\",\n        \"field_type\": \"text\",\n        \"entity_type\": \"customer\",\n        \"required\": true,\n        \"position\": 1,\n        \"options\": [],\n        \"validations\": {}\n      }\n    ]\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Pre-Chat Form",
                  content: "<p>Retrieves dynamic custom fields or default fallback fields for pre-chat registration before starting a conversation.</p>"
                },
                de: {
                  title: "Pre-Chat-Formular abrufen",
                  content: "<p>Ruft dynamische benutzerdefinierte Felder für die Besucherregistrierung vor Beginn eines Chats ab.</p>"
                },
                es: {
                  title: "Obtener Formulario Pre-Chat",
                  content: "<p>Obtiene los campos personalizados dinámicos o campos predeterminados para la presentación del usuario antes de iniciar el chat.</p>"
                },
                fr: {
                  title: "Obtenir le formulaire pré-chat",
                  content: "<p>Récupère les champs personnalisés dynamiques pour l'enregistrement du visiteur avant d'entamer une conversation.</p>"
                },
                "pt-BR": {
                  title: "Obter Formulário Pré-Chat",
                  content: "<p>Retorna os campos personalizados para identificação do cliente antes de iniciar a conversa de suporte.</p>"
                },
                ar: {
                  title: "الحصول على نموذج ما قبل الدردشة",
                  content: "<p>استرجاع الحقول المخصصة لجمع معلومات العميل قبل بدء محادثة الدردشة.</p>"
                },
                ko: {
                  title: "사전 채팅 폼 조회",
                  content: "<p>채팅 시작 전 고객 정보 수집을 위한 동적 사용자 정의 필드 및 필수 입력 항목을 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_help_center_portal,
              article_type: :api_endpoint,
              position: 11,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/help_center",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "description" => "Mobile widget channel public identifier", "required" => true },
                  { "name" => "locale", "type" => "string", "description" => "Language locale", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Help Center portal metadata",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"a9e5f739-61c0-4c0d-8480-765a3d28d7f8\",\n    \"name\": \"Mobile Help Center\",\n    \"locales\": [\"en\", \"es\"],\n    \"default_locale\": \"en\",\n    \"header_title\": \"Help Center\",\n    \"hero_title\": \"How can we help?\",\n    \"hero_subtitle\": \"Search our documentation and guides\",\n    \"categories_count\": 5,\n    \"articles_count\": 42\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Help Center Portal",
                  content: "<p>Retrieves portal branding, localized titles, and category/article counters for in-app knowledge base views.</p>"
                },
                de: {
                  title: "Hilfecenter-Portal abrufen",
                  content: "<p>Ruft Portal-Branding, lokalisierte Titel und Zähler für Wissensdatenbank-Ansichten ab.</p>"
                },
                es: {
                  title: "Obtener Portal del Centro de Ayuda",
                  content: "<p>Obtiene la marca del portal, títulos localizados y contadores de artículos para la base de conocimientos integrada.</p>"
                },
                fr: {
                  title: "Obtenir le portail d'aide",
                  content: "<p>Récupère la marque du portail, les titres localisés et le décompte d'articles de la base de connaissances.</p>"
                },
                "pt-BR": {
                  title: "Obter Portal da Central de Ajuda",
                  content: "<p>Retorna as informações da marca, títulos localizados e contadores de artigos da base de conhecimento.</p>"
                },
                ar: {
                  title: "الحصول على بوابة مركز المساعدة",
                  content: "<p>استرجاع بيانات مركز المساعدة والعناوين المترجمة وعدد المقالات والتصنيفات لقاعدة المعرفة في التطبيق.</p>"
                },
                ko: {
                  title: "고객센터 포털 조회",
                  content: "<p>인앱 도움말 뷰를 위한 포털 브랜드, 다국어 헤더 및 문서 카운터를 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_help_center_categories,
              article_type: :api_endpoint,
              position: 12,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/help_center/categories",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "required" => true },
                  { "name" => "locale", "type" => "string", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of published categories",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"e301b442-5fba-4573-9a84-0a30b59b1a0e\",\n      \"slug\": \"getting-started\",\n      \"name\": \"Getting Started\",\n      \"description\": \"Guides and basics\",\n      \"icon_key\": \"rocket\",\n      \"position\": 1,\n      \"articles_count\": 8\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Help Center Categories",
                  content: "<p>Lists all published public categories with icons and article counters.</p>"
                },
                de: {
                  title: "Hilfecenter-Kategorien auflisten",
                  content: "<p>Listet alle veröffentlichten öffentlichen Kategorien mit Symbolen und Artikelanzahl auf.</p>"
                },
                es: {
                  title: "Listar Categorías del Centro de Ayuda",
                  content: "<p>Enumera todas las categorías públicas publicadas con iconos y número de artículos.</p>"
                },
                fr: {
                  title: "Lister les catégories d'aide",
                  content: "<p>Liste toutes les catégories publiques avec icônes et nombre d'articles.</p>"
                },
                "pt-BR": {
                  title: "Listar Categorias da Central de Ajuda",
                  content: "<p>Lista todas as categorias públicas com ícones e contadores de artigos.</p>"
                },
                ar: {
                  title: "عرض تصنيفات مركز المساعدة",
                  content: "<p>عرض جميع التصنيفات العامة المنشورة مع الأيقونات وعدد المقالات المرتبطة بها.</p>"
                },
                ko: {
                  title: "고객센터 카테고리 목록",
                  content: "<p>아이콘 및 문서 개수를 포함하여 공개된 전체 카테고리 목록을 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_help_center_articles,
              article_type: :api_endpoint,
              position: 13,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/help_center/articles",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "required" => true },
                  { "name" => "category_id", "type" => "string", "description" => "Category UUID or slug filter", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Items per page (default: 20)", "required" => false },
                  { "name" => "locale", "type" => "string", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Paginated list of articles",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"articles\": [\n      {\n        \"id\": \"94bbd632-1b3d-4c31-92b7-a3f2d2012fa1\",\n        \"slug\": \"account-setup\",\n        \"title\": \"How to set up your account\",\n        \"article_type\": \"standard\",\n        \"views_count\": 310,\n        \"description\": \"Setup instructions\",\n        \"category\": { \"id\": \"e301b442\", \"name\": \"Getting Started\", \"slug\": \"getting-started\" }\n      }\n    ],\n    \"pagination\": { \"page\": 1, \"per_page\": 20, \"total_count\": 1, \"total_pages\": 1 }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Help Center Articles",
                  content: "<p>Returns published articles with pagination and optional category filtering.</p>"
                },
                de: {
                  title: "Hilfecenter-Artikel auflisten",
                  content: "<p>Gibt veröffentlichte Artikel mit Paginierung und optionaler Kategoriefilterung zurück.</p>"
                },
                es: {
                  title: "Listar Artículos del Centro de Ayuda",
                  content: "<p>Devuelve artículos publicados con paginación y filtro opcional por categoría.</p>"
                },
                fr: {
                  title: "Lister les articles d'aide",
                  content: "<p>Renvoie les articles publiés avec pagination et filtre facultatif par catégorie.</p>"
                },
                "pt-BR": {
                  title: "Listar Artigos da Central de Ajuda",
                  content: "<p>Retorna artigos publicados com paginação e filtro opcional por categoria.</p>"
                },
                ar: {
                  title: "عرض مقالات مركز المساعدة",
                  content: "<p>عرض مقالات المساعدة المنشورة مع دعم الصفحات وتصفية المقالات حسب التصنيف.</p>"
                },
                ko: {
                  title: "고객센터 문서 목록",
                  content: "<p>페이지네이션 및 카테고리 필터링을 지원하여 공개된 도움말 문서 목록을 조회합니다.</p>"
                }
              }
            },
            {
              key: :sdk_help_center_article_details,
              article_type: :api_endpoint,
              position: 14,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/help_center/articles/:id",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "required" => true },
                  { "name" => "id", "type" => "string", "description" => "Article UUID or slug", "required" => true },
                  { "name" => "locale", "type" => "string", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Full article details",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"94bbd632-1b3d-4c31-92b7-a3f2d2012fa1\",\n    \"slug\": \"account-setup\",\n    \"title\": \"How to set up your account\",\n    \"content\": \"<p>Step 1: Open settings...</p>\",\n    \"reactions\": { \"happy\": 18, \"neutral\": 2, \"sad\": 1 }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Article Details",
                  content: "<p>Retrieves rich HTML content, author metadata, and reaction counts for a single article, incrementing its view counter.</p>"
                },
                de: {
                  title: "Artikeldetails abrufen",
                  content: "<p>Ruft den vollständigen HTML-Inhalt und Feedback-Zähler für einen einzelnen Artikel ab.</p>"
                },
                es: {
                  title: "Obtener Detalles del Artículo",
                  content: "<p>Obtiene el contenido HTML completo, autor y reacciones para un artículo, incrementando sus vistas.</p>"
                },
                fr: {
                  title: "Obtenir les détails de l'article",
                  content: "<p>Récupère le contenu HTML complet, les métadonnées et réactions d'un article.</p>"
                },
                "pt-BR": {
                  title: "Obter Detalhes do Artigo",
                  content: "<p>Retorna o conteúdo HTML completo, dados do autor e reações de um artigo de suporte.</p>"
                },
                ar: {
                  title: "الحصول على تفاصيل المقال",
                  content: "<p>استرجاع محتوى المقال الكامل بتنسيق HTML مع بيانات الكاتب وردود الفعل، وتحديث عداد المشاهدات.</p>"
                },
                ko: {
                  title: "고객센터 문서 상세 조회",
                  content: "<p>단일 문서의 서식 있는 HTML 본문, 작성자 정보 및 피드백 반응을 조회하며 조회수를 1 증가시킵니다.</p>"
                }
              }
            },
            {
              key: :sdk_help_center_search,
              article_type: :api_endpoint,
              position: 15,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/sdk/help_center/search",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "required" => true },
                  { "name" => "q", "type" => "string", "description" => "Search query", "required" => true },
                  { "name" => "locale", "type" => "string", "required" => false },
                  { "name" => "page", "type" => "integer", "required" => false },
                  { "name" => "per_page", "type" => "integer", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Search results matching query",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"articles\": [\n      {\n        \"id\": \"94bbd632\",\n        \"title\": \"How to set up your account\",\n        \"slug\": \"account-setup\"\n      }\n    ],\n    \"pagination\": { \"page\": 1, \"per_page\": 20, \"total_count\": 1, \"total_pages\": 1 }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Search Help Center Articles",
                  content: "<p>Performs full-text search across published article titles and content matching the query string in the active locale.</p>"
                },
                de: {
                  title: "Hilfecenter-Artikel durchsuchen",
                  content: "<p>Führt eine Volltextsuche in veröffentlichten Artikeln durch.</p>"
                },
                es: {
                  title: "Buscar Artículos del Centro de Ayuda",
                  content: "<p>Realiza una búsqueda de texto completo en artículos publicados según la consulta en el idioma activo.</p>"
                },
                fr: {
                  title: "Rechercher des articles d'aide",
                  content: "<p>Effectue une recherche plein texte sur les articles publiés dans la langue active.</p>"
                },
                "pt-BR": {
                  title: "Pesquisar Artigos da Central de Ajuda",
                  content: "<p>Realiza busca textual nos títulos e conteúdos dos artigos publicados no idioma selecionado.</p>"
                },
                ar: {
                  title: "البحث في مقالات مركز المساعدة",
                  content: "<p>إجراء بحث نصي شامل عبر عناوين ومحتوى المقالات المنشورة باللغة المحددة.</p>"
                },
                ko: {
                  title: "고객센터 문서 검색",
                  content: "<p>선택된 언어에 맞춰 공개된 문서 제목과 본문 내용을 대상으로 전체 텍스트 검색을 수행합니다.</p>"
                }
              }
            },
            {
              key: :sdk_help_center_reactions,
              article_type: :api_endpoint,
              position: 16,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/sdk/help_center/articles/:id/reactions",
                "api_parameters" => [
                  { "name" => "X-Deskbolic-App-Id", "type" => "string", "required" => true },
                  { "name" => "id", "type" => "string", "description" => "Article UUID or slug", "required" => true },
                  { "name" => "reaction_type", "type" => "string", "description" => "Sentiment value ('happy', 'neutral', 'sad')", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Reaction recorded successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"message\": \"Reaction recorded successfully\",\n    \"reactions\": { \"happy\": 19, \"neutral\": 2, \"sad\": 1 }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Submit Article Reaction",
                  content: "<p>Submits helpfulness sentiment feedback ('happy', 'neutral', 'sad') for a documentation article.</p>"
                },
                de: {
                  title: "Artikel-Reaktion übermitteln",
                  content: "<p>Sendet Feedback ('happy', 'neutral', 'sad') für einen Dokumentationsartikel.</p>"
                },
                es: {
                  title: "Enviar Reacción a un Artículo",
                  content: "<p>Envía comentarios de satisfacción ('happy', 'neutral', 'sad') para un artículo de documentación.</p>"
                },
                fr: {
                  title: "Envoyer une réaction à l'article",
                  content: "<p>Envoie une évaluation de satisfaction ('happy', 'neutral', 'sad') pour un article.</p>"
                },
                "pt-BR": {
                  title: "Enviar Reação ao Artigo",
                  content: "<p>Envia avaliação de utilidade ('happy', 'neutral', 'sad') para um artigo de documentação.</p>"
                },
                ar: {
                  title: "إرسال تقييم المقال",
                  content: "<p>إرسال تقييم مدى فائدة المقال ('happy' أو 'neutral' أو 'sad') لمقالات المساعدة.</p>"
                },
                ko: {
                  title: "문서 반응 피드백 제출",
                  content: "<p>도움말 문서에 대한 만족도 피드백('happy', 'neutral', 'sad')을 제출합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module IdentityAndProfiles
        def self.category
          {
            key: :profiles_and_me,
            icon_key: "user-check",
            position: 3,
            api_reference: true,
            translations: {
              en: {
                name: "Identity & Profiles",
                description: "Endpoints to retrieve authenticated user context, manage profile details, change passwords, switch tenant workspaces, and update agent availability."
              },
              de: {
                name: "Identität & Profile",
                description: "Endpunkte zum Abrufen des Benutzerkontexts, Aktualisieren von Profildetails, Wechseln von Arbeitsbereichen und Verwalten des Agentenstatus."
              },
              es: {
                name: "Identidad y Perfiles",
                description: "Puntos finales para obtener contexto del usuario autenticado, actualizar perfil, cambiar espacios de trabajo y gestionar disponibilidad."
              },
              fr: {
                name: "Identité et Profils",
                description: "Points de terminaison pour récupérer le profil utilisateur, mettre à jour les informations, changer d'espace de travail et la disponibilité."
              },
              "pt-BR": {
                name: "Identidade e Perfis",
                description: "Endpoints para obter contexto do usuário, atualizar perfil, alternar espaços de trabalho e definir status de disponibilidade."
              },
              ar: {
                name: "الهوية والملفات الشخصية",
                description: "نقاط النهاية لاسترداد سياق المستخدم، وإدارة بيانات الملف الشخصي، وتبديل مساحات العمل، وحالة توفر الوكيل."
              },
              ko: {
                name: "사용자 정보 및 프로필",
                description: "인증된 사용자 컨텍스트 확인, 프로필 정보 수정, 워크스페이스 전환 및 상담원 근무 상태(온라인/오프라인) 업데이트 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :me_get,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/me",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "User and workspace context",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"user\": {\n      \"id\": \"usr_888\",\n      \"email\": \"agent@acme.com\",\n      \"first_name\": \"Sarah\",\n      \"last_name\": \"Connor\",\n      \"display_name\": \"Sarah\",\n      \"locale\": \"en\",\n      \"avatar_url\": \"https://cdn.deskbolic.com/avatars/usr_888.jpg\"\n    },\n    \"accounts\": [\n      {\n        \"id\": \"acc_123\",\n        \"name\": \"Acme Global Support\",\n        \"identifier\": \"acme-global\"\n      }\n    ],\n    \"current_account\": {\n      \"id\": \"acc_123\",\n      \"name\": \"Acme Global Support\",\n      \"identifier\": \"acme-global\"\n    },\n    \"availability\": \"online\",\n    \"role\": \"owner\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Current Identity (Me)",
                  content: "<p>Returns extended profile details for the authenticated user along with the list of accessible workspace accounts, active workspace context, role, and availability.</p>"
                },
                de: {
                  title: "Aktuelle Identität abrufen (Me)",
                  content: "<p>Gibt erweiterte Profildetails des authentifizierten Benutzers, Arbeitsbereiche, Rolle und Verfügbarkeitsstatus zurück.</p>"
                },
                es: {
                  title: "Obtener Identidad Actual (Me)",
                  content: "<p>Devuelve los detalles de perfil del usuario autenticado, espacios de trabajo, rol y estado de disponibilidad.</p>"
                },
                fr: {
                  title: "Obtenir l'identité actuelle (Me)",
                  content: "<p>Renvoie les détails du profil de l'utilisateur authentifié, les espaces de travail, le rôle et la disponibilité.</p>"
                },
                "pt-BR": {
                  title: "Obter Identidade Atual (Me)",
                  content: "<p>Retorna os detalhes do perfil do usuário autenticado, espaços de trabalho, função e status de disponibilidade.</p>"
                },
                ar: {
                  title: "الحصول على الهوية الحالية (Me)",
                  content: "<p>يعيد تفاصيل الملف الشخصي للمستخدم الذي تمت مصادقته مع مساحات العمل المتاحة والدور وحالة التوفر.</p>"
                },
                ko: {
                  title: "현재 사용자 정보 조회 (Me)",
                  content: "<p>인증된 사용자의 확장 프로필 및 접근 가능한 워크스페이스 목록, 역할 및 근무 상태를 반환합니다.</p>"
                }
              }
            },
            {
              key: :me_profile_patch,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/me/profile",
                "api_parameters" => [
                  { "name" => "first_name", "type" => "string", "description" => "User first name", "required" => false },
                  { "name" => "last_name", "type" => "string", "description" => "User last name", "required" => false },
                  { "name" => "display_name", "type" => "string", "description" => "Public display name shown to customers", "required" => false },
                  { "name" => "locale", "type" => "string", "description" => "Preferred user locale (en, de, es, fr, pt-BR, ar, ko)", "required" => false },
                  { "name" => "password", "type" => "string", "description" => "New password (min 8 chars, 1 uppercase, 1 symbol)", "required" => false },
                  { "name" => "password_confirmation", "type" => "string", "description" => "New password confirmation", "required" => false },
                  { "name" => "current_password", "type" => "string", "description" => "Required when changing password", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Profile updated successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"usr_888\",\n    \"first_name\": \"Sarah\",\n    \"last_name\": \"Connor\",\n    \"display_name\": \"Sarah C.\",\n    \"locale\": \"de\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Profile & Password",
                  content: "<p>Updates user first name, last name, display name, preferred locale, or changes password.</p>"
                },
                de: {
                  title: "Profil & Passwort aktualisieren",
                  content: "<p>Aktualisiert Vorname, Nachname, Anzeigename, Sprache oder ändert das Passwort.</p>"
                },
                es: {
                  title: "Actualizar Perfil y Contraseña",
                  content: "<p>Actualiza el nombre, apellido, nombre visible, idioma preferido o cambia la contraseña.</p>"
                },
                fr: {
                  title: "Mettre à jour le profil et le mot de passe",
                  content: "<p>Met à jour le prénom, le nom, le nom d'affichage, la langue ou modifie le mot de passe.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Perfil e Senha",
                  content: "<p>Atualiza o nome, sobrenome, nome de exibição, idioma ou altera a senha da conta.</p>"
                },
                ar: {
                  title: "تحديث الملف الشخصي وكلمة المرور",
                  content: "<p>يقوم بتحديث الاسم الأول والأخير والاسم المعروض واللغة المفضلة أو تغيير كلمة المرور.</p>"
                },
                ko: {
                  title: "프로필 및 비밀번호 수정",
                  content: "<p>사용자 이름, 성, 표시 이름, 기본 언어를 수정하거나 비밀번호를 변경합니다.</p>"
                }
              }
            },
            {
              key: :me_availability_patch,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/me/availability",
                "api_parameters" => [
                  { "name" => "availability", "type" => "string", "description" => "Availability state: 'online' or 'offline'", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Status updated successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"availability\": \"online\",\n    \"availability_changed_at\": \"2026-10-10T14:30:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Availability Status",
                  content: "<p>Updates the agent's real-time availability status between <code>online</code> and <code>offline</code> for intelligent conversation auto-assignment.</p>"
                },
                de: {
                  title: "Verfügbarkeitsstatus aktualisieren",
                  content: "<p>Aktualisiert den Verfügbarkeitsstatus des Agenten zwischen <code>online</code> und <code>offline</code>.</p>"
                },
                es: {
                  title: "Actualizar Disponibilidad",
                  content: "<p>Actualiza el estado de disponibilidad en tiempo real entre <code>online</code> y <code>offline</code>.</p>"
                },
                fr: {
                  title: "Mettre à jour la disponibilité",
                  content: "<p>Met à jour le statut de disponibilité en temps réel entre <code>online</code> et <code>offline</code>.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Disponibilidade",
                  content: "<p>Atualiza o status de disponibilidade do agente entre <code>online</code> e <code>offline</code>.</p>"
                },
                ar: {
                  title: "تحديث حالة التوفر",
                  content: "<p>يقوم بتحديث حالة توفر الوكيل المباشرة بين <code>online</code> و <code>offline</code> لإعادة توجيه المحادثات التلقائية.</p>"
                },
                ko: {
                  title: "근무 상태(온라인/오프라인) 변경",
                  content: "<p>자동 대화 배정을 위해 상담원의 실시간 근무 상태를 <code>online</code> 또는 <code>offline</code>으로 변경합니다.</p>"
                }
              }
            },
            {
              key: :me_switch_account,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/me/switch_account/{account_id}",
                "api_parameters" => [
                  { "name" => "account_id", "type" => "string", "description" => "Target Account ID to switch context to", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Switched active workspace successfully",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Switched to account Acme Global Support successfully\",\n  \"data\": {\n    \"token\": \"eyJhbGciOiJIUzI1NiJ9...\",\n    \"account\": {\n      \"id\": \"acc_123\",\n      \"name\": \"Acme Global Support\",\n      \"identifier\": \"acme-global\"\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Switch Workspace Account",
                  content: "<p>Switches the active workspace tenant for multi-tenant users, returning a refreshed JWT token scoped to the specified account.</p>"
                },
                de: {
                  title: "Arbeitsbereich wechseln",
                  content: "<p>Wechselt den aktiven Arbeitsbereich für Multi-Tenant-Benutzer und gibt ein aktualisiertes JWT-Token zurück.</p>"
                },
                es: {
                  title: "Cambiar Espacio de Trabajo",
                  content: "<p>Cambia el espacio de trabajo activo para usuarios multiinquilino y devuelve un nuevo token JWT.</p>"
                },
                fr: {
                  title: "Changer d'espace de travail",
                  content: "<p>Bascule l'espace de travail actif pour les utilisateurs multi-locataires et renvoie un jeton JWT mis à jour.</p>"
                },
                "pt-BR": {
                  title: "Alternar Espaço de Trabalho",
                  content: "<p>Alterna o espaço de trabalho ativo para usuários multilocatários e retorna um novo token JWT.</p>"
                },
                ar: {
                  title: "تبديل مساحة العمل",
                  content: "<p>يبدل مساحة العمل النشطة للمستخدمين متعددي الحسابات ويعيد رمز JWT محدثاً.</p>"
                },
                ko: {
                  title: "워크스페이스 전환",
                  content: "<p>다중 워크스페이스 사용자의 활성 작업 공간을 전환하고 해당 계정 범위의 새로운 JWT 토큰을 발급받습니다.</p>"
                }
              }
            },
            {
              key: :me_cable_token,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/me/cable_token",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "WebSocket connection credentials",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"connection_token\": \"cbl_tok_7a9f2...\",\n    \"action_cable_url\": \"wss://ws.deskbolic.com\",\n    \"channels\": [\n      {\n        \"name\": \"SubscriptionChannel\",\n        \"params\": {\n          \"connection_token\": \"cbl_tok_7a9f2...\"\n        }\n      }\n    ]\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Real-time WebSocket Token",
                  content: "<p>Generates an ActionCable real-time connection token and URL to subscribe to live updates (incoming messages, agent typing indicators, conversation state changes).</p>"
                },
                de: {
                  title: "Echtzeit-WebSocket-Token abrufen",
                  content: "<p>Generiert ein Verbindungstoken für ActionCable zur Synchronisierung von Live-Nachrichten und Schreibindikatoren.</p>"
                },
                es: {
                  title: "Obtener Token de WebSocket en Tiempo Real",
                  content: "<p>Genera un token de conexión de ActionCable para recibir actualizaciones en tiempo real.</p>"
                },
                fr: {
                  title: "Obtenir le jeton WebSocket en temps réel",
                  content: "<p>Génère un jeton de connexion ActionCable pour s'abonner aux mises à jour en direct.</p>"
                },
                "pt-BR": {
                  title: "Obter Token de WebSocket em Tempo Real",
                  content: "<p>Gera um token de conexão ActionCable para receber atualizações em tempo real.</p>"
                },
                ar: {
                  title: "الحصول على رمز WebSocket في الوقت الفعلي",
                  content: "<p>يُنشئ رمز اتصال ActionCable للاشتراك في التحديثات المباشرة والإشعارات الفورية.</p>"
                },
                ko: {
                  title: "실시간 웹소켓 토큰 조회",
                  content: "<p>실시간 메시지 및 타이핑 인디케이터 수신을 위한 ActionCable 웹소켓 토큰 및 접속 URL을 반환합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

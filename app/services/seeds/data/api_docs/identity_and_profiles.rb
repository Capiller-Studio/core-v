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
                description: "Endpoints to retrieve authenticated user context, manage profile details, change passwords, and update agent availability."
              },
              de: {
                name: "Identität & Profile",
                description: "Endpunkte zum Abrufen des Benutzerkontexts, Aktualisieren von Profildetails und Verwalten des Agentenstatus."
              },
              es: {
                name: "Identidad y Perfiles",
                description: "Puntos finales para obtener contexto del usuario autenticado, actualizar perfil y gestionar disponibilidad."
              },
              fr: {
                name: "Identité et Profils",
                description: "Points de terminaison pour récupérer le profil utilisateur, mettre à jour les informations et la disponibilité."
              },
              "pt-BR": {
                name: "Identidade e Perfis",
                description: "Endpoints para obter contexto do usuário, atualizar perfil e definir status de disponibilidade."
              },
              ar: {
                name: "الهوية والملفات الشخصية",
                description: "نقاط النهاية لاسترداد سياق المستخدم، وإدارة بيانات الملف الشخصي، وحالة توفر الوكيل."
              },
              ko: {
                name: "사용자 정보 및 프로필",
                description: "인증된 사용자 컨텍스트 확인, 프로필 정보 수정 및 상담원 근무 상태(온라인/오프라인) 업데이트 엔드포인트입니다."
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
                    "body" => "{\n  \"data\": {\n    \"user\": {\n      \"id\": \"usr_888\",\n      \"email\": \"agent@acme.com\",\n      \"name\": \"Sarah Connor\",\n      \"display_name\": \"Sarah\",\n      \"locale\": \"en\",\n      \"avatar_url\": \"https://cdn.deskbolic.com/avatars/usr_888.jpg\"\n    },\n    \"accounts\": [\n      {\n        \"id\": \"acc_123\",\n        \"name\": \"Acme Global Support\",\n        \"identifier\": \"acme-global\"\n      }\n    ],\n    \"current_account\": {\n      \"id\": \"acc_123\",\n      \"name\": \"Acme Global Support\",\n      \"identifier\": \"acme-global\"\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Current Identity (Me)",
                  content: "<p>Returns extended profile details for the authenticated user along with the list of accessible workspace accounts and the active workspace context.</p>"
                },
                de: {
                  title: "Aktuelle Identität abrufen (Me)",
                  content: "<p>Gibt erweiterte Profildetails des authentifizierten Benutzers und die Liste der verfügbaren Arbeitsbereiche zurück.</p>"
                },
                es: {
                  title: "Obtener Identidad Actual (Me)",
                  content: "<p>Devuelve los detalles de perfil del usuario autenticado y la lista de espacios de trabajo accesibles.</p>"
                },
                fr: {
                  title: "Obtenir l'identité actuelle (Me)",
                  content: "<p>Renvoie les détails du profil de l'utilisateur authentifié et les espaces de travail associés.</p>"
                },
                "pt-BR": {
                  title: "Obter Identidade Atual (Me)",
                  content: "<p>Retorna os detalhes do perfil do usuário autenticado e os espaços de trabalho associados.</p>"
                },
                ar: {
                  title: "الحصول على الهوية الحالية (Me)",
                  content: "<p>يعيد تفاصيل الملف الشخصي للمستخدم الذي تمت مصادقته مع مساحات العمل المتاحة.</p>"
                },
                ko: {
                  title: "현재 사용자 정보 조회 (Me)",
                  content: "<p>인증된 사용자의 확장 프로필 및 접근 가능한 워크스페이스 목록을 반환합니다.</p>"
                }
              }
            },
            {
              key: :me_cable_token,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/me/cable_token",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "WebSocket connection credentials",
                    "body" => "{\n  \"data\": {\n    \"connection_token\": \"cbl_tok_7a9f2...\",\n    \"action_cable_url\": \"wss://ws.deskbolic.com\",\n    \"channels\": [\n      {\n        \"name\": \"SubscriptionChannel\",\n        \"params\": {\n          \"connection_token\": \"cbl_tok_7a9f2...\"\n        }\n      }\n    ]\n  }\n}"
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
            },
            {
              key: :profile_get,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/profile",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Current profile details",
                    "body" => "{\n  \"data\": {\n    \"user\": {\n      \"id\": \"usr_888\",\n      \"email\": \"agent@acme.com\",\n      \"first_name\": \"Sarah\",\n      \"last_name\": \"Connor\",\n      \"display_name\": \"Sarah\"\n    },\n    \"current_account\": {\n      \"id\": \"acc_123\",\n      \"name\": \"Acme Global Support\"\n    },\n    \"availability\": \"online\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Profile",
                  content: "<p>Returns profile details for the current user in the active workspace along with their current availability status.</p>"
                },
                de: {
                  title: "Profil abrufen",
                  content: "<p>Gibt Profildetails des Benutzers und dessen aktuellen Verfügbarkeitsstatus zurück.</p>"
                },
                es: {
                  title: "Obtener Perfil",
                  content: "<p>Devuelve los detalles del perfil del usuario y su estado de disponibilidad actual.</p>"
                },
                fr: {
                  title: "Obtenir le profil",
                  content: "<p>Renvoie les détails du profil de l'utilisateur et son statut de disponibilité.</p>"
                },
                "pt-BR": {
                  title: "Obter Perfil",
                  content: "<p>Retorna os detalhes do perfil do usuário e seu status de disponibilidade atual.</p>"
                },
                ar: {
                  title: "عرض الملف الشخصي",
                  content: "<p>يعيد تفاصيل الملف الشخصي للمستخدم الحالي وحالة التوفر في مساحة العمل النشطة.</p>"
                },
                ko: {
                  title: "프로필 조회",
                  content: "<p>현재 워크스페이스에서의 사용자 프로필 정보 및 상담원 근무 상태를 반환합니다.</p>"
                }
              }
            },
            {
              key: :profile_patch,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/profile",
                "api_parameters" => [
                  { "name" => "first_name", "type" => "string", "description" => "User first name", "required" => false },
                  { "name" => "last_name", "type" => "string", "description" => "User last name", "required" => false },
                  { "name" => "display_name", "type" => "string", "description" => "Public display name shown to customers", "required" => false },
                  { "name" => "locale", "type" => "string", "description" => "Preferred user locale (en, de, es, fr, pt-BR, ar, ko)", "required" => false },
                  { "name" => "password", "type" => "string", "description" => "New password (if changing)", "required" => false },
                  { "name" => "password_confirmation", "type" => "string", "description" => "New password confirmation", "required" => false },
                  { "name" => "current_password", "type" => "string", "description" => "Required when changing password", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Profile updated successfully",
                    "body" => "{\n  \"data\": {\n    \"id\": \"usr_888\",\n    \"name\": \"Sarah Connor\",\n    \"display_name\": \"Sarah C.\",\n    \"locale\": \"de\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Profile & Password",
                  content: "<p>Updates user account name, display name, preferred locale, or changes password.</p>"
                },
                de: {
                  title: "Profil & Passwort aktualisieren",
                  content: "<p>Aktualisiert den Benutzernamen, Anzeigenamen, die Sprache oder ändert das Passwort.</p>"
                },
                es: {
                  title: "Actualizar Perfil y Contraseña",
                  content: "<p>Actualiza el nombre del usuario, nombre visible, idioma preferido o cambia la contraseña.</p>"
                },
                fr: {
                  title: "Mettre à jour le profil et le mot de passe",
                  content: "<p>Met à jour le nom, le nom d'affichage, la langue ou modifie le mot de passe.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Perfil e Senha",
                  content: "<p>Atualiza o nome, nome de exibição, idioma ou altera a senha da conta.</p>"
                },
                ar: {
                  title: "تحديث الملف الشخصي وكلمة المرور",
                  content: "<p>يقوم بتحديث الاسم، والاسم المعروض، واللغة المفضلة أو تغيير كلمة المرور.</p>"
                },
                ko: {
                  title: "프로필 및 비밀번호 수정",
                  content: "<p>사용자 이름, 표시 이름, 기본 언어를 수정하거나 비밀번호를 변경합니다.</p>"
                }
              }
            },
            {
              key: :profile_availability,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/profile/availability",
                "api_parameters" => [
                  { "name" => "availability", "type" => "string", "description" => "Availability state: 'online' or 'offline'", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Status updated",
                    "body" => "{\n  \"data\": {\n    \"availability\": \"online\",\n    \"availability_changed_at\": \"2026-09-02T14:30:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Agent Availability Status",
                  content: "<p>Updates the agent's real-time availability status between <code>online</code> and <code>offline</code> for intelligent auto-assignment routing.</p>"
                },
                de: {
                  title: "Agenten-Verfügbarkeitsstatus aktualisieren",
                  content: "<p>Aktualisiert den Verfügbarkeitsstatus des Agenten zwischen <code>online</code> und <code>offline</code>.</p>"
                },
                es: {
                  title: "Actualizar Disponibilidad del Agente",
                  content: "<p>Actualiza el estado de disponibilidad en tiempo real entre <code>online</code> y <code>offline</code>.</p>"
                },
                fr: {
                  title: "Mettre à jour la disponibilité de l'agent",
                  content: "<p>Met à jour le statut de disponibilité en temps réel entre <code>online</code> et <code>offline</code>.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Disponibilidade do Agente",
                  content: "<p>Atualiza o status de disponibilidade do agente entre <code>online</code> e <code>offline</code>.</p>"
                },
                ar: {
                  title: "تحديث حالة توفر الوكيل",
                  content: "<p>يقوم بتحديث حالة توفر الوكيل المباشرة بين <code>online</code> و <code>offline</code> لإعادة توجيه المحادثات التلقائية.</p>"
                },
                ko: {
                  title: "상담원 근무 상태(온라인/오프라인) 변경",
                  content: "<p>자동 대화 배정을 위해 상담원의 실시간 근무 상태를 <code>online</code> 또는 <code>offline</code>으로 변경합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Authentication
        def self.category
          {
            key: :auth,
            icon_key: "lock",
            position: 2,
            api_reference: true,
            translations: {
              en: {
                name: "Authentication & Sessions",
                description: "Endpoints for authenticating users, managing JWT sessions, password recovery, and mobile registration."
              },
              de: {
                name: "Authentifizierung & Sitzungen",
                description: "Endpunkte für Benutzerauthentifizierung, JWT-Sitzungen, Passwort-Wiederherstellung und Registrierung."
              },
              es: {
                name: "Autenticación y Sesiones",
                description: "Puntos finales para autenticación de usuarios, sesiones JWT, recuperación de contraseña y registro."
              },
              fr: {
                name: "Authentification et Sessions",
                description: "Points de terminaison pour l'authentification des utilisateurs, les sessions JWT et la récupération de mot de passe."
              },
              "pt-BR": {
                name: "Autenticação e Sessões",
                description: "Endpoints para autenticação de usuários, sessões JWT, recuperação de senha e cadastro móvel."
              },
              ar: {
                name: "المصادقة والجلسات",
                description: "نقاط النهاية لمصادقة المستخدمين، وإدارة جلسات JWT، واستعادة كلمات المرور والتسجيل."
              },
              ko: {
                name: "인증 및 세션",
                description: "사용자 인증, JWT 세션 발급, 비밀번호 재설정 및 모바일 가입을 위한 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :sessions_create,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/sessions",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "Registered user email address", "required" => true },
                  { "name" => "password", "type" => "string", "description" => "Account password", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Authentication successful",
                    "body" => "{\n  \"data\": {\n    \"token\": \"eyJhbGciOiJIUzI1NiJ9...\",\n    \"user\": {\n      \"id\": \"usr_888\",\n      \"email\": \"agent@acme.com\",\n      \"name\": \"Sarah Connor\",\n      \"display_name\": \"Sarah\",\n      \"role\": \"agent\"\n    }\n  }\n}"
                  },
                  {
                    "status" => 401,
                    "description" => "Invalid credentials",
                    "body" => "{\n  \"errors\": [\n    {\n      \"code\": \"invalid_credentials\",\n      \"message\": \"Invalid email or password\"\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Session (Sign In)",
                  content: "<p>Authenticates an agent or admin using email and password credentials, returning a signed JWT token and user profile object.</p>"
                },
                de: {
                  title: "Sitzung erstellen (Anmelden)",
                  content: "<p>Authentifiziert einen Benutzer mit E-Mail und Passwort und gibt ein signiertes JWT-Token zurück.</p>"
                },
                es: {
                  title: "Crear Sesión (Iniciar Sesión)",
                  content: "<p>Autentica a un usuario mediante correo electrónico y contraseña, devolviendo un token JWT.</p>"
                },
                fr: {
                  title: "Créer une session (Connexion)",
                  content: "<p>Authentifie un utilisateur avec e-mail et mot de passe, renvoyant un jeton JWT.</p>"
                },
                "pt-BR": {
                  title: "Criar Sessão (Login)",
                  content: "<p>Autentica um usuário usando e-mail e senha, retornando um token JWT assinado.</p>"
                },
                ar: {
                  title: "إنشاء جلسة (تسجيل الدخول)",
                  content: "<p>يقوم بمصادقة المستخدم باستخدام البريد الإلكتروني وكلمة المرور، مع إرجاع رمز JWT صالح.</p>"
                },
                ko: {
                  title: "세션 생성 (로그인)",
                  content: "<p>이메일과 비밀번호로 사용자를 인증하고 서명된 JWT 토큰을 반환합니다.</p>"
                }
              }
            },
            {
              key: :passwords_forgot,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/passwords/forgot",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "User account email", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Instructions dispatched",
                    "body" => "{\n  \"data\": {\n    \"message\": \"If your email is registered with us, you will receive password reset instructions.\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Request Password Reset",
                  content: "<p>Sends password reset instructions to the provided email address if the account exists.</p>"
                },
                de: {
                  title: "Passwort-Zurücksetzung anfordern",
                  content: "<p>Sendet Anweisungen zum Zurücksetzen des Passworts an die angegebene E-Mail-Adresse.</p>"
                },
                es: {
                  title: "Solicitar Restablecimiento de Contraseña",
                  content: "<p>Envía instrucciones para restablecer la contraseña al correo electrónico proporcionado.</p>"
                },
                fr: {
                  title: "Demander la réinitialisation du mot de passe",
                  content: "<p>Envoie des instructions de réinitialisation de mot de passe à l'adresse e-mail indiquée.</p>"
                },
                "pt-BR": {
                  title: "Solicitar Redefinição de Senha",
                  content: "<p>Envia instruções de redefinição de senha para o e-mail informado.</p>"
                },
                ar: {
                  title: "طلب إعادة تعيين كلمة المرور",
                  content: "<p>يرسل تعليمات إعادة تعيين كلمة المرور إلى عنوان البريد الإلكتروني المحدد.</p>"
                },
                ko: {
                  title: "비밀번호 재설정 요청",
                  content: "<p>등록된 이메일 주소로 비밀번호 재설정 지침 링크를 전송합니다.</p>"
                }
              }
            },
            {
              key: :passwords_reset,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/passwords/reset",
                "api_parameters" => [
                  { "name" => "reset_password_token", "type" => "string", "description" => "Token received in email", "required" => true },
                  { "name" => "password", "type" => "string", "description" => "New password (min 8 chars, mixed case, number, symbol)", "required" => true },
                  { "name" => "password_confirmation", "type" => "string", "description" => "Matching password confirmation", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Password updated",
                    "body" => "{\n  \"data\": {\n    \"message\": \"Password has been successfully reset. Please log in with your new password.\"\n  }\n}"
                  },
                  {
                    "status" => 422,
                    "description" => "Validation failed",
                    "body" => "{\n  \"errors\": [\n    {\n      \"field\": \"reset_password_token\",\n      \"message\": \"is invalid or expired\"\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Reset Password with Token",
                  content: "<p>Validates the reset token and updates the user account password.</p>"
                },
                de: {
                  title: "Passwort mit Token zurücksetzen",
                  content: "<p>Überprüft das Token und aktualisiert das Benutzerpasswort.</p>"
                },
                es: {
                  title: "Restablecer Contraseña con Token",
                  content: "<p>Valida el token de restablecimiento y actualiza la contraseña.</p>"
                },
                fr: {
                  title: "Réinitialiser le mot de passe avec le jeton",
                  content: "<p>Valide le jeton et met à jour le mot de passe du compte.</p>"
                },
                "pt-BR": {
                  title: "Redefinir Senha com Token",
                  content: "<p>Valida o token de redefinição e atualiza a senha da conta.</p>"
                },
                ar: {
                  title: "إعادة تعيين كلمة المرور باستخدام الرمز",
                  content: "<p>يتحقق من صحة الرمز ويقوم بتحديث كلمة المرور لحساب المستخدم.</p>"
                },
                ko: {
                  title: "토큰으로 비밀번호 재설정",
                  content: "<p>재설정 토큰을 확인하고 새 비밀번호를 설정합니다.</p>"
                }
              }
            },
            {
              key: :registrations_create,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/registrations",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "User email address", "required" => true },
                  { "name" => "password", "type" => "string", "description" => "User password", "required" => true },
                  { "name" => "first_name", "type" => "string", "description" => "First name", "required" => false },
                  { "name" => "last_name", "type" => "string", "description" => "Last name", "required" => false },
                  { "name" => "account_name", "type" => "string", "description" => "Workspace / company name", "required" => false },
                  { "name" => "invitation_token", "type" => "string", "description" => "Invitation token if joining team", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Registration successful",
                    "body" => "{\n  \"data\": {\n    \"token\": \"eyJhbGciOiJIUzI1NiJ9...\",\n    \"user\": {\n      \"id\": \"usr_101\",\n      \"email\": \"alex@startup.io\",\n      \"name\": \"Alex Rivera\"\n    },\n    \"account\": {\n      \"id\": \"acc_555\",\n      \"name\": \"Startup Inc\",\n      \"identifier\": \"startup-inc\"\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Register User / Account",
                  content: "<p>Registers a new user, optionally creates a new workspace account or accepts an invitation token.</p>"
                },
                de: {
                  title: "Benutzer / Konto registrieren",
                  content: "<p>Registriert einen neuen Benutzer und erstellt optional ein neues Workspace-Konto.</p>"
                },
                es: {
                  title: "Registrar Usuario / Cuenta",
                  content: "<p>Registra un nuevo usuario y, opcionalmente, crea una nueva cuenta de espacio de trabajo.</p>"
                },
                fr: {
                  title: "Enregistrer un utilisateur / compte",
                  content: "<p>Enregistre un nouvel utilisateur et crée éventuellement un nouvel espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Registrar Usuário / Conta",
                  content: "<p>Registra um novo usuário e opcionalmente cria uma nova conta de espaço de trabalho.</p>"
                },
                ar: {
                  title: "تسجيل مستخدم / حساب جديد",
                  content: "<p>يسجل مستخدمًا جديدًا، وينشئ اختياريًا مساحة عمل جديدة أو يقبل رمز دعوة.</p>"
                },
                ko: {
                  title: "사용자 / 계정 회원가입",
                  content: "<p>새 사용자를 등록하고 워크스페이스를 생성하거나 초대 토큰을 수락합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

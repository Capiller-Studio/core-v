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
                description: "Endpoints for authenticating users, managing JWT sessions, password recovery, and account registration."
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
                description: "Endpoints para autenticação de usuários, sessões JWT, recuperação de senha e cadastro."
              },
              ar: {
                name: "المصادقة والجلسات",
                description: "نقاط النهاية لمصادقة المستخدمين، وإدارة جلسات JWT، واستعادة كلمات المرور والتسجيل."
              },
              ko: {
                name: "인증 및 세션",
                description: "사용자 인증, JWT 세션 발급, 비밀번호 재설정 및 신규 계정 가입 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :auth_login,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/auth/login",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "Registered user email address", "required" => true },
                  { "name" => "password", "type" => "string", "description" => "Account password", "required" => true },
                  { "name" => "device_name", "type" => "string", "description" => "Optional device identifier", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Authentication successful",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"token\": \"eyJhbGciOiJIUzI1NiJ9...\",\n    \"user\": {\n      \"id\": \"usr_888\",\n      \"email\": \"sarah@acme.com\",\n      \"name\": \"Sarah Connor\",\n      \"display_name\": \"Sarah\",\n      \"roles\": [\"agent\"]\n    },\n    \"account\": {\n      \"id\": \"acc_001\",\n      \"name\": \"Acme Corp\",\n      \"identifier\": \"acme\"\n    }\n  }\n}"
                  },
                  {
                    "status" => 401,
                    "description" => "Invalid credentials",
                    "body" => "{\n  \"success\": false,\n  \"errors\": [\n    {\n      \"code\": \"invalid_credentials\",\n      \"message\": \"Invalid email or password\"\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "User Login",
                  content: "<p>Authenticates an agent or administrator using email and password, returning a signed JWT access token, user entity, and active account context.</p>"
                },
                de: {
                  title: "Benutzer-Anmeldung",
                  content: "<p>Authentifiziert einen Benutzer mit E-Mail und Passwort und gibt ein signiertes JWT-Token und das Konto zurück.</p>"
                },
                es: {
                  title: "Inicio de Sesión",
                  content: "<p>Autentica a un usuario mediante correo electrónico y contraseña, devolviendo un token JWT y la cuenta activa.</p>"
                },
                fr: {
                  title: "Connexion utilisateur",
                  content: "<p>Authentifie un utilisateur avec e-mail et mot de passe, renvoyant un jeton JWT et le compte actif.</p>"
                },
                "pt-BR": {
                  title: "Login de Usuário",
                  content: "<p>Autentica um usuário usando e-mail e senha, retornando um token JWT assinado e a conta ativa.</p>"
                },
                ar: {
                  title: "تسجيل الدخول",
                  content: "<p>يقوم بمصادقة المستخدم باستخدام البريد الإلكتروني وكلمة المرور، مع إرجاع رمز JWT وسياق الحساب النشط.</p>"
                },
                ko: {
                  title: "사용자 로그인",
                  content: "<p>이메일과 비밀번호로 상담원 또는 관리자를 인증하고 서명된 JWT 액세스 토큰 및 활성 워크스페이스 정보를 반환합니다.</p>"
                }
              }
            },
            {
              key: :auth_register,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/auth/register",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "User email address", "required" => true },
                  { "name" => "password", "type" => "string", "description" => "Account password (min 8 chars, 1 uppercase, 1 symbol)", "required" => true },
                  { "name" => "first_name", "type" => "string", "description" => "User first name", "required" => false },
                  { "name" => "last_name", "type" => "string", "description" => "User last name", "required" => false },
                  { "name" => "account_name", "type" => "string", "description" => "Workspace account name", "required" => false },
                  { "name" => "as_affiliate", "type" => "boolean", "description" => "Whether to register as an affiliate partner", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Registration successful",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"token\": \"eyJhbGciOiJIUzI1NiJ9...\",\n    \"user\": {\n      \"id\": \"usr_889\",\n      \"email\": \"alex@acme.com\",\n      \"first_name\": \"Alex\",\n      \"last_name\": \"Rivera\"\n    },\n    \"account\": {\n      \"id\": \"acc_002\",\n      \"name\": \"Acme Systems\"\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Register Account & User",
                  content: "<p>Registers a new user and provisions a new workspace tenant account with owner privileges.</p>"
                },
                de: {
                  title: "Konto & Benutzer registrieren",
                  content: "<p>Registriert einen neuen Benutzer und erstellt einen neuen Mandanten-Arbeitsbereich mit Eigentümerrechten.</p>"
                },
                es: {
                  title: "Registrar Cuenta y Usuario",
                  content: "<p>Registra un nuevo usuario y crea un nuevo espacio de trabajo con privilegios de propietario.</p>"
                },
                fr: {
                  title: "Créer un compte et un utilisateur",
                  content: "<p>Inscrit un nouvel utilisateur et configure un nouvel espace de travail avec les privilèges de propriétaire.</p>"
                },
                "pt-BR": {
                  title: "Cadastrar Conta e Usuário",
                  content: "<p>Registra um novo usuário e cria um novo espaço de trabalho com privilégios de proprietário.</p>"
                },
                ar: {
                  title: "تسجيل الحساب والمستخدم",
                  content: "<p>يسجل مستخدماً جديداً وينشئ مساحة عمل جديدة بامتيازات المالك.</p>"
                },
                ko: {
                  title: "신규 계정 및 워크스페이스 등록",
                  content: "<p>신규 사용자를 등록하고 소유자 권한을 가진 새 워크스페이스를 프로비저닝합니다.</p>"
                }
              }
            },
            {
              key: :auth_logout,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/auth/logout",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Logged out",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Logged out successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "User Logout",
                  content: "<p>Invalidates the current session and clears authentication cookies.</p>"
                },
                de: {
                  title: "Benutzer-Abmeldung",
                  content: "<p>Beendet die aktuelle Sitzung und löscht Authentifizierungs-Cookies.</p>"
                },
                es: {
                  title: "Cerrar Sesión",
                  content: "<p>Invalida la sesión actual y borra las cookies de autenticación.</p>"
                },
                fr: {
                  title: "Déconnexion utilisateur",
                  content: "<p>Invalide la session en cours et efface les cookies d'authentification.</p>"
                },
                "pt-BR": {
                  title: "Logout de Usuário",
                  content: "<p>Encerra a sessão atual e limpa os cookies de autenticação.</p>"
                },
                ar: {
                  title: "تسجيل الخروج",
                  content: "<p>يبطل الجلسة الحالية ويمسح ملفات تعريف الارتباط للمصادقة.</p>"
                },
                ko: {
                  title: "로그아웃",
                  content: "<p>현재 세션을 무효화하고 인증 쿠키를 삭제합니다.</p>"
                }
              }
            },
            {
              key: :auth_refresh,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/auth/refresh",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Token refreshed",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"token\": \"eyJhbGciOiJIUzI1NiJ9...\",\n    \"user\": {\n      \"id\": \"usr_888\",\n      \"name\": \"Sarah Connor\"\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Refresh Session Token",
                  content: "<p>Issues a refreshed JWT session token for the authenticated user without requiring credentials re-entry.</p>"
                },
                de: {
                  title: "Sitzungstoken aktualisieren",
                  content: "<p>Gibt ein neues JWT-Sitzungstoken für den angemeldeten Benutzer aus.</p>"
                },
                es: {
                  title: "Actualizar Token de Sesión",
                  content: "<p>Emite un token JWT actualizado para el usuario autenticado.</p>"
                },
                fr: {
                  title: "Actualiser le jeton de session",
                  content: "<p>Émet un jeton de session JWT actualisé pour l'utilisateur authentifié.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Token de Sessão",
                  content: "<p>Emite um novo token JWT de sessão para o usuário autenticado.</p>"
                },
                ar: {
                  title: "تحديث رمز الجلسة",
                  content: "<p>يصدر رمز جلسة JWT محدث للمستخدم المصادق عليه.</p>"
                },
                ko: {
                  title: "세션 토큰 갱신",
                  content: "<p>재로그인 없이 인증된 사용자의 새로운 JWT 액세스 토큰을 발급받습니다.</p>"
                }
              }
            },
            {
              key: :auth_password_forgot,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/auth/password/forgot",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "Registered user email address", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Reset instructions sent",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"If your email exists in our system, you will receive password reset instructions.\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Forgot Password",
                  content: "<p>Initiates a password recovery request and emails a secure reset link with token.</p>"
                },
                de: {
                  title: "Passwort vergessen",
                  content: "<p>Initiiert eine Passwort-Wiederherstellungsanfrage per E-Mail.</p>"
                },
                es: {
                  title: "Olvidé mi Contraseña",
                  content: "<p>Inicia una solicitud de recuperación de contraseña por correo electrónico.</p>"
                },
                fr: {
                  title: "Mot de passe oublié",
                  content: "<p>Initie une demande de récupération de mot de passe par e-mail.</p>"
                },
                "pt-BR": {
                  title: "Esqueci Minha Senha",
                  content: "<p>Inicia uma solicitação de recuperação de senha por e-mail.</p>"
                },
                ar: {
                  title: "نسيت كلمة المرور",
                  content: "<p>يبدأ طلب استعادة كلمة المرور ويرسل رابط إعادة تعيين آمن عبر البريد الإلكتروني.</p>"
                },
                ko: {
                  title: "비밀번호 재설정 요청",
                  content: "<p>등록된 이메일로 안전한 비밀번호 재설정 링크와 토큰을 발송합니다.</p>"
                }
              }
            },
            {
              key: :auth_password_reset,
              article_type: :api_endpoint,
              position: 6,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/auth/password/reset",
                "api_parameters" => [
                  { "name" => "reset_password_token", "type" => "string", "description" => "Token received in email", "required" => true },
                  { "name" => "password", "type" => "string", "description" => "New password (min 8 chars, 1 uppercase, 1 symbol)", "required" => true },
                  { "name" => "password_confirmation", "type" => "string", "description" => "Confirmation matching password", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Password reset successfully",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Password has been successfully reset. Please log in with your new password.\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Reset Password",
                  content: "<p>Resets the account password using the secure token received via email.</p>"
                },
                de: {
                  title: "Passwort zurücksetzen",
                  content: "<p>Setzt das Kontopasswort mit dem sicheren Token zurück.</p>"
                },
                es: {
                  title: "Restablecer Contraseña",
                  content: "<p>Restablece la contraseña de la cuenta utilizando el token seguro.</p>"
                },
                fr: {
                  title: "Réinitialiser le mot de passe",
                  content: "<p>Réinitialise le mot de passe du compte à l'aide du jeton sécurisé.</p>"
                },
                "pt-BR": {
                  title: "Redefinir Senha",
                  content: "<p>Redefine a senha da conta usando o token seguro recebido por e-mail.</p>"
                },
                ar: {
                  title: "إعادة تعيين كلمة المرور",
                  content: "<p>يعيد تعيين كلمة مرور الحساب باستخدام الرمز الآمن المستلم عبر البريد الإلكتروني.</p>"
                },
                ko: {
                  title: "비밀번호 재설정 완료",
                  content: "<p>이메일로 전달받은 보안 토큰을 사용하여 새로운 비밀번호로 변경합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

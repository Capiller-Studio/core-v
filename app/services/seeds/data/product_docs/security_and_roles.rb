# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module SecurityAndRoles
        def self.category
          {
            key: :security_and_roles,
            icon_key: "shield",
            position: 9,
            translations: {
              en: {
                name: "Security, Roles & Permissions",
                description: "Manage role-based access control (RBAC), enforce two-factor authentication, audit logs, and session policies."
              },
              de: {
                name: "Sicherheit, Rollen & Berechtigungen",
                description: "Verwalten Sie Rollen, Berechtigungen (RBAC) und Zwei-Faktor-Authentifizierung (2FA)."
              },
              es: {
                name: "Seguridad, Roles y Permisos",
                description: "Gestione control de acceso basado en roles (RBAC), autenticación de dos factores y registros."
              },
              fr: {
                name: "Sécurité, Rôles et Permissions",
                description: "Gérez le contrôle d'accès basé sur les rôles (RBAC), la double authentification et les sessions."
              },
              "pt-BR": {
                name: "Segurança, Funções e Permissões",
                description: "Gerencie controle de acesso baseado em funções (RBAC), autenticação de dois fatores e sessões."
              },
              ar: {
                name: "الأمان والأدوار والأذونات",
                description: "إدارة التحكم في الوصول المستند إلى الأدوار (RBAC)، والمصادقة الثنائية (2FA)، وسجلات التدقيق."
              },
              ko: {
                name: "보안, 권한 및 역할 관리",
                description: "역할 기반 접근 제어(RBAC), 2단계 인증(2FA), 세션 보안 및 감사 로그 관리 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :roles_and_permissions,
              position: 1,
              translations: {
                en: {
                  title: "User Roles & Granular Permissions",
                  content: <<~HTML
                    <p>Deskbolic offers structured role-based access control to maintain workspace integrity and data privacy.</p>
                    <h3>Default Roles</h3>
                    <ul>
                      <li><strong>Owner:</strong> Full workspace control including billing, account deletion, and custom domain configuration.</li>
                      <li><strong>Admin:</strong> Can invite agents, create inboxes, manage automation rules, and view team analytics.</li>
                      <li><strong>Agent:</strong> Can view assigned inboxes, respond to customers, create contacts, and manage assigned tickets.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Benutzerrollen & Berechtigungen",
                  content: "<p>Deskbolic bietet rollenbasierte Zugriffskontrolle (Inhaber, Administrator, Agent).</p>"
                },
                es: {
                  title: "Roles de Usuario y Permisos",
                  content: "<p>Deskbolic ofrece control de acceso basado en roles (Propietario, Administrador, Agente).</p>"
                },
                fr: {
                  title: "Rôles Utilisateurs et Permissions",
                  content: "<p>Deskbolic propose un contrôle d'accès granulaire (Propriétaire, Administrateur, Agent).</p>"
                },
                "pt-BR": {
                  title: "Funções de Usuário e Permissões",
                  content: "<p>O Deskbolic oferece controle de acesso baseado em funções (Proprietário, Administrador, Atendente).</p>"
                },
                ar: {
                  title: "أدوار المستخدمين والأذونات",
                  content: "<p>يوفر Deskbolic تحكمًا دقيقًا في الوصول استنادًا إلى الأدوار (المالك، المسؤول، الوكيل).</p>"
                },
                ko: {
                  title: "사용자 역할 및 세부 권한 설정",
                  content: "<p>소유자(Owner), 관리자(Admin), 상담원(Agent) 등 역할별 권한을 설정하여 데이터 보안을 유지합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

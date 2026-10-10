# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module AgentsAndTeams
        def self.category
          {
            key: :agents_and_teams,
            icon_key: "shield",
            position: 10,
            api_reference: true,
            translations: {
              en: {
                name: "Agents & Teams",
                description: "Endpoints to manage workspace agents, team structures, roles, availability status, and collaborator assignments."
              },
              de: {
                name: "Agenten & Teams",
                description: "Endpunkte zur Verwaltung von Agenten, Teamstrukturen, Rollen und Zuweisungen."
              },
              es: {
                name: "Agentes y Equipos",
                description: "Puntos finales para gestionar agentes, estructuras de equipo, roles y asignaciones."
              },
              fr: {
                name: "Agents et Équipes",
                description: "Points de terminaison pour gérer les agents, les structures d'équipe, les rôles et les assignations."
              },
              "pt-BR": {
                name: "Atendentes e Equipes",
                description: "Endpoints para gerenciar atendentes, estruturas de equipe, funções e atribuições."
              },
              ar: {
                name: "الوكلاء وفرق العمل",
                description: "نقاط النهاية لإدارة وكلاء مساحة العمل وهياكل الفرق والأدوار وحالة التوفر."
              },
              ko: {
                name: "상담원 및 팀 관리",
                description: "상담원 초대, 팀 조직 구성, 역할 권한, 근무 상태 및 팀원 배정 관리 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :agents_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/agents",
                "api_parameters" => [
                  { "name" => "availability", "type" => "string", "description" => "'online' or 'offline'", "required" => false },
                  { "name" => "query", "type" => "string", "description" => "Search by name or email", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of agents",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"usr_888\",\n      \"name\": \"Sarah Connor\",\n      \"email\": \"sarah@acme.com\",\n      \"availability\": \"online\",\n      \"roles\": [\"agent\"]\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Agents",
                  content: "<p>Returns a paginated list of all team members and agents in the workspace with their roles and availability status.</p>"
                },
                de: {
                  title: "Agenten auflisten",
                  content: "<p>Gibt eine Liste aller Teammitglieder und Agenten mit Verfügbarkeitsstatus zurück.</p>"
                },
                es: {
                  title: "Listar Agentes",
                  content: "<p>Devuelve una lista de todos los agentes en el espacio de trabajo con su estado de disponibilidad.</p>"
                },
                fr: {
                  title: "Lister les agents",
                  content: "<p>Renvoie la liste de tous les agents de l'espace de travail avec leur statut.</p>"
                },
                "pt-BR": {
                  title: "Listar Atendentes",
                  content: "<p>Retorna uma lista de todos os atendentes com seu status de disponibilidade.</p>"
                },
                ar: {
                  title: "عرض قائمة الوكلاء",
                  content: "<p>يعيد قائمة بجميع الوكلاء في مساحة العمل مع أدوارهم وحالة التوفر.</p>"
                },
                ko: {
                  title: "상담원 목록 조회",
                  content: "<p>워크스페이스에 등록된 전체 팀원 및 상담원 목록과 실시간 근무 상태를 반환합니다.</p>"
                }
              }
            },
            {
              key: :agents_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/agents",
                "api_parameters" => [
                  { "name" => "email", "type" => "string", "description" => "Agent email address", "required" => true },
                  { "name" => "name", "type" => "string", "description" => "Agent full name", "required" => false },
                  { "name" => "role", "type" => "string", "description" => "'agent' or 'admin'", "required" => false },
                  { "name" => "team_ids", "type" => "array[string]", "description" => "Teams to assign", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Agent invited",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"usr_889\",\n    \"email\": \"alex@acme.com\",\n    \"name\": \"Alex Rivers\"\n  },\n  \"message\": \"Agent invited successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Invite Agent",
                  content: "<p>Invites a new teammate to the workspace and configures initial role permissions.</p>"
                },
                de: {
                  title: "Agent einladen",
                  content: "<p>Lädt ein neues Teammitglied in den Arbeitsbereich ein.</p>"
                },
                es: {
                  title: "Invitar Agente",
                  content: "<p>Invita a un nuevo compañero de equipo al espacio de trabajo.</p>"
                },
                fr: {
                  title: "Inviter un agent",
                  content: "<p>Invite un nouveau coéquipier dans l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Convidar Atendente",
                  content: "<p>Convida um novo membro para o espaço de trabalho.</p>"
                },
                ar: {
                  title: "دعوة وكيل",
                  content: "<p>يدعو زميل عمل جديد إلى مساحة العمل ويحدد صلاحيات الدور الأولية.</p>"
                },
                ko: {
                  title: "상담원 초대",
                  content: "<p>새로운 팀원을 워크스페이스에 초대하고 초기 권한 및 소속 팀을 구성합니다.</p>"
                }
              }
            },
            {
              key: :teams_list,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/teams",
                "api_parameters" => [
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of teams",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"tm_301\",\n      \"name\": \"Technical Support\",\n      \"description\": \"Tier 2 Technical Escalations\",\n      \"member_count\": 4,\n      \"created_at\": \"2026-08-01T10:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Teams",
                  content: "<p>Returns the list of teams (departments/groups) configured in the workspace for conversation routing.</p>"
                },
                de: {
                  title: "Teams auflisten",
                  content: "<p>Gibt die Liste der im Arbeitsbereich konfigurierten Teams zurück.</p>"
                },
                es: {
                  title: "Listar Equipos",
                  content: "<p>Devuelve la lista de equipos configurados en el espacio de trabajo.</p>"
                },
                fr: {
                  title: "Lister les équipes",
                  content: "<p>Renvoie la liste des équipes configurées dans l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Listar Equipes",
                  content: "<p>Retorna a lista de equipes configuradas no espaço de trabalho.</p>"
                },
                ar: {
                  title: "عرض قائمة الفرق",
                  content: "<p>يعيد قائمة الفرق (الأقسام/المجموعات) في مساحة العمل لتوجيه المحادثات.</p>"
                },
                ko: {
                  title: "팀 목록 조회",
                  content: "<p>대화 자동 배정 및 부서별 관리를 위해 워크스페이스에 생성된 팀 목록을 반환합니다.</p>"
                }
              }
            },
            {
              key: :teams_create,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/teams",
                "api_parameters" => [
                  { "name" => "name", "type" => "string", "description" => "Team name", "required" => true },
                  { "name" => "description", "type" => "string", "description" => "Team mission description", "required" => false },
                  { "name" => "auto_assign", "type" => "boolean", "description" => "Enable round-robin auto assignment", "required" => false },
                  { "name" => "user_ids", "type" => "array[string]", "description" => "Initial member user UUIDs", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Team created",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"tm_302\",\n    \"name\": \"Billing Operations\",\n    \"member_count\": 2\n  },\n  \"message\": \"Team created successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Team",
                  content: "<p>Creates a specialized department or operational team for routing and escalation.</p>"
                },
                de: {
                  title: "Team erstellen",
                  content: "<p>Erstellt ein spezialisiertes Team für Routing und Eskalation.</p>"
                },
                es: {
                  title: "Crear Equipo",
                  content: "<p>Crea un equipo especializado para enrutamiento y escalamiento.</p>"
                },
                fr: {
                  title: "Créer une équipe",
                  content: "<p>Crée une équipe spécialisée pour le routage et l'escalade.</p>"
                },
                "pt-BR": {
                  title: "Criar Equipe",
                  content: "<p>Cria uma equipe especializada para roteamento e escalonamento.</p>"
                },
                ar: {
                  title: "إنشاء فريق",
                  content: "<p>ينشئ فريقًا متخصصًا للتوجيه والتصعيد.</p>"
                },
                ko: {
                  title: "팀 생성",
                  content: "<p>대화 분배 및 에스컬레이션을 위한 전문 상담 팀(부서)을 생성합니다.</p>"
                }
              }
            },
            {
              key: :teams_members_manage,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/teams/:id/members",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Team UUID", "required" => true },
                  { "name" => "user_id", "type" => "string", "description" => "Agent user UUID to assign", "required" => true },
                  { "name" => "role", "type" => "string", "description" => "'member' or 'lead' (default: 'member')", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Member added",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"user_id\": \"usr_888\",\n    \"role\": \"lead\"\n  },\n  \"message\": \"Team member added successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Add Team Member",
                  content: "<p>Assigns an agent to the team with member or lead role permissions.</p>"
                },
                de: {
                  title: "Teammitglied hinzufügen",
                  content: "<p>Weist einen Agenten dem Team mit Mitglieds- oder Leiterrolle zu.</p>"
                },
                es: {
                  title: "Agregar Miembro al Equipo",
                  content: "<p>Asigna un agente al equipo con permisos de miembro o líder.</p>"
                },
                fr: {
                  title: "Ajouter un membre à l'équipe",
                  content: "<p>Assigne un agent à l'équipe avec des autorisations de membre ou de chef.</p>"
                },
                "pt-BR": {
                  title: "Adicionar Membro à Equipe",
                  content: "<p>Atribui um atendente à equipe com permissões de membro ou líder.</p>"
                },
                ar: {
                  title: "إضافة عضو إلى الفريق",
                  content: "<p>يعين وكيلاً للفريق بصلاحيات عضو أو قائد فريق.</p>"
                },
                ko: {
                  title: "팀원 배정",
                  content: "<p>상담원을 팀에 일반 멤버 또는 팀장(Lead) 역할로 배정합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

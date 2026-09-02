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
                description: "Endpoints to list workspace agents, view availability status, and manage team department assignments."
              },
              de: {
                name: "Agenten & Teams",
                description: "Endpunkte zum Auflisten von Agenten, Einsehen des Status und Verwalten von Teams."
              },
              es: {
                name: "Agentes y Equipos",
                description: "Puntos finales para listar agentes, ver estado de disponibilidad y gestionar equipos."
              },
              fr: {
                name: "Agents et Équipes",
                description: "Points de terminaison pour lister les agents, afficher la disponibilité et gérer les équipes."
              },
              "pt-BR": {
                name: "Atendentes e Equipes",
                description: "Endpoints para listar atendentes, verificar disponibilidade e gerenciar equipes."
              },
              ar: {
                name: "الوكلاء وفرق العمل",
                description: "نقاط النهاية لسرد وكلاء مساحة العمل، وعرض حالة التوفر، وإدارة الفرق والأقسام."
              },
              ko: {
                name: "상담원 및 팀 관리",
                description: "워크스페이스 내 상담원 목록 조회, 실시간 근무 상태 확인 및 부서별 팀 정보 조회 엔드포인트입니다."
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
                  { "name" => "availability", "type" => "string", "description" => "Filter by availability: 'online' or 'offline'", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-100, default: 50)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of workspace agents",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"usr_888\",\n      \"name\": \"Sarah Connor\",\n      \"display_name\": \"Sarah\",\n      \"email\": \"sarah@acme.com\",\n      \"availability\": \"online\",\n      \"role\": \"agent\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Agents",
                  content: "<p>Returns a list of all team members and agents in the current workspace with their availability status.</p>"
                },
                de: {
                  title: "Agenten auflisten",
                  content: "<p>Gibt eine Liste aller Teammitglieder und Agenten mit Verfügbarkeitsstatus zurück.</p>"
                },
                es: {
                  title: "Listar Agentes",
                  content: "<p>Devuelve una lista de todos los miembros del equipo y agentes con su estado de disponibilidad.</p>"
                },
                fr: {
                  title: "Lister les agents",
                  content: "<p>Renvoie la liste de tous les agents de l'espace de travail avec leur statut de disponibilité.</p>"
                },
                "pt-BR": {
                  title: "Listar Atendentes",
                  content: "<p>Retorna uma lista de todos os membros e atendentes com seu status de disponibilidade.</p>"
                },
                ar: {
                  title: "عرض قائمة الوكلاء",
                  content: "<p>يعيد قائمة بجميع أعضاء الفريق والوكلاء في مساحة العمل الحالية مع حالة التوفر الخاصة بهم.</p>"
                },
                ko: {
                  title: "상담원 목록 조회",
                  content: "<p>현재 워크스페이스에 소속된 전체 팀원 및 상담원 목록과 실시간 근무 상태를 반환합니다.</p>"
                }
              }
            },
            {
              key: :teams_list,
              article_type: :api_endpoint,
              position: 2,
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
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"tm_301\",\n      \"name\": \"Technical Support\",\n      \"description\": \"Tier 2 Technical Escalations\",\n      \"created_at\": \"2026-08-01T10:00:00Z\"\n    },\n    {\n      \"id\": \"tm_302\",\n      \"name\": \"Billing & Accounts\",\n      \"description\": \"Invoices and Payments\",\n      \"created_at\": \"2026-08-01T10:05:00Z\"\n    }\n  ]\n}"
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
                  content: "<p>يعيد قائمة الفرق (الأقسام/المجموعات) التي تم تكوينها في مساحة العمل لتوجيه المحادثات.</p>"
                },
                ko: {
                  title: "팀 목록 조회",
                  content: "<p>대화 자동 배정 및 부서별 관리를 위해 워크스페이스에 생성된 팀 목록을 반환합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

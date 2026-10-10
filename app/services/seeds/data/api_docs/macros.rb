# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Macros
        def self.category
          {
            key: :macros,
            icon_key: "play-circle",
            position: 15,
            api_reference: true,
            translations: {
              en: {
                name: "Macros",
                description: "Automate repetitive workflows with one-click actions: update status, assign teams, and send canned replies."
              },
              de: {
                name: "Makros",
                description: "Automatisieren Sie wiederkehrende Abläufe mit 1-Klick-Aktionen für Konversationen."
              },
              es: {
                name: "Macros",
                description: "Automatice flujos repetitivos con acciones de un solo clic en conversaciones."
              },
              fr: {
                name: "Macros",
                description: "Automatisez les tâches répétitives en un clic sur les conversations."
              },
              "pt-BR": {
                name: "Macros",
                description: "Automatize fluxos repetitivos com ações de um clique em conversas."
              },
              ar: {
                name: "الماكرو والأتمتة اليدوية",
                description: "أتمتة سير العمل المتكرر بإجراءات بنقرة واحدة على المحادثات."
              },
              ko: {
                name: "매크로",
                description: "반복적인 업무를 한 번의 클릭으로 자동 실행하는 매크로 관리 및 실행 API입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :macros_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/macros",
                "api_parameters" => [
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-100, default: 50)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of accessible macros",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"mcr_101\",\n      \"name\": \"Close & Mark Resolved\",\n      \"visibility\": \"account_wide\",\n      \"status\": \"active\",\n      \"action_names\": [\"set_status\"],\n      \"actions\": [\n        { \"action\": \"set_status\", \"params\": { \"status\": \"resolved\" } }\n      ]\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Macros",
                  content: "Returns all macros visible to the authenticated user, including account-wide, team-scoped, and personal macros."
                }
              }
            },
            {
              key: :macros_execute,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/macros/:id/execute",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Macro UUID", "required" => true },
                  { "name" => "conversation_id", "type" => "string", "description" => "Target conversation UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Execution result",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"status\": \"success\",\n    \"succeeded_count\": 1,\n    \"failed_count\": 0,\n    \"results\": [\n      { \"action\": \"set_status\", \"params\": { \"status\": \"resolved\" }, \"result\": \"success\" }\n    ],\n    \"conversation\": {\n      \"id\": \"cnv_777\",\n      \"status\": \"resolved\"\n    }\n  },\n  \"message\": \"Macro executed with status: success\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Execute Macro",
                  content: "Executes the defined macro actions against a target conversation synchronously and returns the updated conversation state."
                }
              }
            }
          ]
        end
      end
    end
  end
end

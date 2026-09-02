# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module CannedResponses
        def self.category
          {
            key: :canned_responses,
            icon_key: "zap",
            position: 12,
            api_reference: true,
            translations: {
              en: {
                name: "Canned Responses",
                description: "Endpoints to search and retrieve pre-written saved replies and macros for fast agent messaging."
              },
              de: {
                name: "Textbausteine",
                description: "Endpunkte zum Durchsuchen und Abrufen von vorgefertigten Antworten und Makros."
              },
              es: {
                name: "Respuestas Guardadas",
                description: "Puntos finales para buscar y recuperar respuestas predefinidas y macros rápidas."
              },
              fr: {
                name: "Réponses Préenregistrées",
                description: "Points de terminaison pour rechercher et récupérer des modèles de réponses rapides."
              },
              "pt-BR": {
                name: "Respostas Rápidas",
                description: "Endpoints para pesquisar e recuperar respostas prontas e macros para atendimento ágil."
              },
              ar: {
                name: "الردود الجاهزة",
                description: "نقاط النهاية للبحث عن الردود المحفوظة مسبقًا واسترجاعها للمراسلة السريعة للوكلاء."
              },
              ko: {
                name: "자주 쓰는 답변 (상용구)",
                description: "신속한 고객 응대를 위한 템플릿(자주 쓰는 답변 및 매크로) 검색 및 조회 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :canned_responses_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/canned_responses",
                "api_parameters" => [
                  { "name" => "search", "type" => "string", "description" => "Search query matching title, shortcut code, or content", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of canned responses",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"can_88\",\n      \"name\": \"Refund Policy\",\n      \"identifier\": \"!refund\",\n      \"content\": \"Our refund policy allows full returns within 30 days of purchase.\",\n      \"created_at\": \"2026-08-01T12:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Canned Responses",
                  content: "<p>Returns a paginated list of canned responses and macros with optional keyword and shortcut search filtering.</p>"
                },
                de: {
                  title: "Textbausteine auflisten",
                  content: "<p>Gibt eine paginierte Liste von Textbausteinen und Makros zurück.</p>"
                },
                es: {
                  title: "Listar Respuestas Guardadas",
                  content: "<p>Devuelve una lista paginada de respuestas guardadas con filtrado opcional por palabra clave.</p>"
                },
                fr: {
                  title: "Lister les réponses préenregistrées",
                  content: "<p>Renvoie une liste paginée de modèles de réponses rapides.</p>"
                },
                "pt-BR": {
                  title: "Listar Respostas Rápidas",
                  content: "<p>Retorna uma lista paginada de respostas rápidas com filtro opcional por palavra-chave.</p>"
                },
                ar: {
                  title: "عرض الردود الجاهزة",
                  content: "<p>يعيد قائمة مقسمة إلى صفحات بالردود الجاهزة مع إمكانية البحث بالاختصارات والكلمات المفتاحية.</p>"
                },
                ko: {
                  title: "자주 쓰는 답변 목록 조회",
                  content: "<p>키워드 및 단축키 검색을 지원하는 자주 쓰는 답변 목록을 페이지네이션하여 반환합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

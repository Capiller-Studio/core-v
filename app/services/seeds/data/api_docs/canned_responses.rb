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
                description: "Endpoints to search, create, update, and manage pre-written saved replies for quick agent messaging."
              },
              de: {
                name: "Textbausteine",
                description: "Endpunkte zum Durchsuchen, Erstellen und Verwalten vorgefertigter Antworten."
              },
              es: {
                name: "Respuestas Guardadas",
                description: "Puntos finales para buscar, crear y administrar respuestas predefinidas."
              },
              fr: {
                name: "Réponses Préenregistrées",
                description: "Points de terminaison pour rechercher, créer et gérer des modèles de réponses rapides."
              },
              "pt-BR": {
                name: "Respostas Rápidas",
                description: "Endpoints para pesquisar, criar e gerenciar respostas prontas para atendimento ágil."
              },
              ar: {
                name: "الردود الجاهزة",
                description: "نقاط النهاية للبحث عن الردود المحفوظة مسبقًا وإنشائها وإدارتها."
              },
              ko: {
                name: "자주 쓰는 답변 (상용구)",
                description: "신속한 고객 응대를 위한 템플릿(자주 쓰는 답변) 검색, 생성, 수정 및 삭제 엔드포인트입니다."
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
                  { "name" => "query", "type" => "string", "description" => "Search query matching shortcut code or content", "required" => false },
                  { "name" => "inbox_id", "type" => "string", "description" => "Filter by inbox UUID", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of canned responses",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"can_88\",\n      \"short_code\": \"refund\",\n      \"content\": \"Our refund policy allows full returns within 30 days of purchase.\",\n      \"created_at\": \"2026-08-01T12:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Canned Responses",
                  content: "<p>Returns a paginated list of canned responses with optional keyword and shortcut search filtering.</p>"
                },
                de: {
                  title: "Textbausteine auflisten",
                  content: "<p>Gibt eine paginierte Liste von Textbausteinen zurück.</p>"
                },
                es: {
                  title: "Listar Respuestas Guardadas",
                  content: "<p>Devuelve una lista paginada de respuestas guardadas con filtro opcional por palabra clave.</p>"
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
            },
            {
              key: :canned_responses_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/canned_responses",
                "api_parameters" => [
                  { "name" => "short_code", "type" => "string", "description" => "Short code trigger (e.g. 'refund')", "required" => true },
                  { "name" => "content", "type" => "string", "description" => "Template text content", "required" => true },
                  { "name" => "inbox_id", "type" => "string", "description" => "Optional inbox UUID to scope to", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Canned response created",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"can_89\",\n    \"short_code\": \"hours\",\n    \"content\": \"Our business hours are Mon-Fri 9am to 6pm EST.\"\n  },\n  \"message\": \"Canned response created successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Canned Response",
                  content: "<p>Creates a new saved reply snippet with a unique short code.</p>"
                },
                de: {
                  title: "Textbaustein erstellen",
                  content: "<p>Erstellt einen neuen Textbaustein mit einem eindeutigen Kürzel.</p>"
                },
                es: {
                  title: "Crear Respuesta Guardada",
                  content: "<p>Crea una nueva respuesta guardada con un código corto único.</p>"
                },
                fr: {
                  title: "Créer une réponse préenregistrée",
                  content: "<p>Crée un nouveau modèle de réponse avec un raccourci unique.</p>"
                },
                "pt-BR": {
                  title: "Criar Resposta Rápida",
                  content: "<p>Cria uma nova resposta rápida com um atalho exclusivo.</p>"
                },
                ar: {
                  title: "إنشاء رد جاهز",
                  content: "<p>ينشئ ردًا محفوظًا جديدًا مع رمز اختصار فريد.</p>"
                },
                ko: {
                  title: "자주 쓰는 답변 등록",
                  content: "<p>고유 단축 코드를 가진 새로운 빠른 답변 상용구를 등록합니다.</p>"
                }
              }
            },
            {
              key: :canned_responses_delete,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/canned_responses/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Canned Response UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Canned response deleted",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Canned response deleted successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Delete Canned Response",
                  content: "<p>Deletes an existing canned response template.</p>"
                },
                de: {
                  title: "Textbaustein löschen",
                  content: "<p>Löscht einen vorhandenen Textbaustein.</p>"
                },
                es: {
                  title: "Eliminar Respuesta Guardada",
                  content: "<p>Elimina una respuesta guardada existente.</p>"
                },
                fr: {
                  title: "Supprimer la réponse préenregistrée",
                  content: "<p>Supprime un modèle de réponse existant.</p>"
                },
                "pt-BR": {
                  title: "Excluir Resposta Rápida",
                  content: "<p>Remove uma resposta rápida existente.</p>"
                },
                ar: {
                  title: "حذف الرد الجاهز",
                  content: "<p>يحذف قالب الرد الجاهز الحالي.</p>"
                },
                ko: {
                  title: "자주 쓰는 답변 삭제",
                  content: "<p>기존 자주 쓰는 답변 템플릿을 삭제합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

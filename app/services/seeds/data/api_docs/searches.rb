# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Searches
        def self.category
          {
            key: :searches,
            icon_key: "search",
            position: 15,
            api_reference: true,
            translations: {
              en: {
                name: "Search",
                description: "Full-text search endpoints across conversations, message history, contacts, and custom filters."
              },
              de: {
                name: "Suche",
                description: "Volltextsuche über Konversationen, Nachrichten und Kontakte."
              },
              es: {
                name: "Búsqueda",
                description: "Puntos finales de búsqueda de texto completo en conversaciones y mensajes."
              },
              fr: {
                name: "Recherche",
                description: "Points de terminaison de recherche en texte intégral dans les conversations et les messages."
              },
              "pt-BR": {
                name: "Busca",
                description: "Endpoints de busca de texto completo em conversas, mensagens e contatos."
              },
              ar: {
                name: "البحث",
                description: "نقاط النهاية للبحث بالنص الكامل في المحادثات وسجل الرسائل وجهات الاتصال."
              },
              ko: {
                name: "통합 검색",
                description: "대화, 메시지 본문 및 고객 연락처에 대한 전문(Full-text) 검색 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :search_query,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/search",
                "api_parameters" => [
                  { "name" => "q", "type" => "string", "description" => "Search query term", "required" => true },
                  { "name" => "type", "type" => "string", "description" => "Filter by resource: 'conversations' or 'messages'", "required" => false },
                  { "name" => "inbox_id", "type" => "string", "description" => "Filter by inbox UUID", "required" => false },
                  { "name" => "status", "type" => "string", "description" => "Filter by status: 'active', 'closed', 'snoozed', 'resolved'", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-50, default: 20)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Search results",
                    "body" => "{\n  \"data\": {\n    \"conversations\": [\n      {\n        \"id\": \"cnv_777\",\n        \"identifier\": \"CNV-1029\",\n        \"title\": \"Payment Gateway Error\"\n      }\n    ],\n    \"messages\": [\n      {\n        \"id\": \"msg_001\",\n        \"content\": \"I have an error on payment checkout\"\n      }\n    ]\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Search Conversations & Messages",
                  content: "<p>Executes an intelligent full-text search across conversations, message content, and customer identifiers with multi-attribute filtering.</p>"
                },
                de: {
                  title: "Konversationen & Nachrichten durchsuchen",
                  content: "<p>Führt eine intelligente Volltextsuche über Konversationen und Nachrichteninhalte durch.</p>"
                },
                es: {
                  title: "Buscar Conversaciones y Mensajes",
                  content: "<p>Ejecuta una búsqueda de texto completo en conversaciones y mensajes.</p>"
                },
                fr: {
                  title: "Rechercher des conversations et des messages",
                  content: "<p>Exécute une recherche en texte intégral dans les conversations et les messages.</p>"
                },
                "pt-BR": {
                  title: "Buscar Conversas e Mensagens",
                  content: "<p>Executa uma busca em texto completo nas conversas e no conteúdo das mensagens.</p>"
                },
                ar: {
                  title: "البحث في المحادثات والرسائل",
                  content: "<p>ينفذ بحثًا ذكيًا بالنص الكامل عبر المحادثات ومحتوى الرسائل ومعرفات العملاء.</p>"
                },
                ko: {
                  title: "대화 및 메시지 통합 검색",
                  content: "<p>대화 제목, 메시지 본문 및 고객 정보를 대상으로 필터링을 포함한 전문(Full-text) 검색을 수행합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

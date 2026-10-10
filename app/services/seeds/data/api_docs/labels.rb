# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Labels
        def self.category
          {
            key: :labels,
            icon_key: "tag",
            position: 11,
            api_reference: true,
            translations: {
              en: {
                name: "Labels & Tags",
                description: "Endpoints to list, create, update, and manage workspace labels and color-coded tags for conversation taxonomy."
              },
              de: {
                name: "Labels & Tags",
                description: "Endpunkte zum Auflisten, Erstellen und Verwalten von Labels zur Konversationsklassifizierung."
              },
              es: {
                name: "Etiquetas y Tags",
                description: "Puntos finales para listar, crear y gestionar etiquetas para la clasificación de conversaciones."
              },
              fr: {
                name: "Étiquettes et Tags",
                description: "Points de terminaison pour lister, créer et gérer des étiquettes pour classer les conversations."
              },
              "pt-BR": {
                name: "Rótulos e Tags",
                description: "Endpoints para listar, criar e gerenciar rótulos coloridos para classificação de conversas."
              },
              ar: {
                name: "التسميات والعلامات",
                description: "نقاط النهاية لسرد وإنشاء وتحديث تسميات مساحة العمل والعلامات الملونة لتصنيف المحادثات."
              },
              ko: {
                name: "라벨 및 태그",
                description: "상담 대화 분류 및 필터링을 위한 워크스페이스 라벨(태그) 목록 조회, 생성, 수정 및 삭제 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :labels_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/labels",
                "api_parameters" => [
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of labels",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"lbl_12\",\n      \"title\": \"Bug Report\",\n      \"color\": \"#EF4444\",\n      \"description\": \"Software defects\"\n    },\n    {\n      \"id\": \"lbl_14\",\n      \"title\": \"Feature Request\",\n      \"color\": \"#3B82F6\",\n      \"description\": \"User product suggestions\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_count\": 2\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Labels",
                  content: "<p>Returns all active labels and tags created in the workspace.</p>"
                },
                de: {
                  title: "Labels auflisten",
                  content: "<p>Gibt alle im Arbeitsbereich erstellten Labels zurück.</p>"
                },
                es: {
                  title: "Listar Etiquetas",
                  content: "<p>Devuelve todas las etiquetas activas creadas en el espacio de trabajo.</p>"
                },
                fr: {
                  title: "Lister les étiquettes",
                  content: "<p>Renvoie toutes les étiquettes actives créées dans l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Listar Rótulos",
                  content: "<p>Retorna todos os rótulos ativos criados no espaço de trabalho.</p>"
                },
                ar: {
                  title: "عرض قائمة التسميات",
                  content: "<p>يعيد جميع التسميات والعلامات النشطة التي تم إنشاؤها في مساحة العمل.</p>"
                },
                ko: {
                  title: "라벨 목록 조회",
                  content: "<p>워크스페이스에 생성된 모든 활성 라벨(태그) 목록을 반환합니다.</p>"
                }
              }
            },
            {
              key: :labels_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/labels",
                "api_parameters" => [
                  { "name" => "title", "type" => "string", "description" => "Unique label title", "required" => true },
                  { "name" => "color", "type" => "string", "description" => "Hex color code (e.g. '#10B981')", "required" => false },
                  { "name" => "description", "type" => "string", "description" => "Label purpose description", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Label created",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"lbl_15\",\n    \"title\": \"Security Concern\",\n    \"color\": \"#F59E0B\"\n  },\n  \"message\": \"Label created successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Label",
                  content: "<p>Creates a new color-coded label definition for conversations.</p>"
                },
                de: {
                  title: "Label erstellen",
                  content: "<p>Erstellt eine neue farbcodierte Label-Definition.</p>"
                },
                es: {
                  title: "Crear Etiqueta",
                  content: "<p>Crea una nueva definición de etiqueta codificada por colores.</p>"
                },
                fr: {
                  title: "Créer une étiquette",
                  content: "<p>Crée une nouvelle définition d'étiquette avec code couleur.</p>"
                },
                "pt-BR": {
                  title: "Criar Rótulo",
                  content: "<p>Cria uma nova definição de rótulo colorido para conversas.</p>"
                },
                ar: {
                  title: "إنشاء تسمية",
                  content: "<p>ينشئ تعريف تسمية جديد برمز لوني للمحادثات.</p>"
                },
                ko: {
                  title: "라벨 생성",
                  content: "<p>상담 대화 분류에 사용할 새로운 색상 라벨(태그)을 생성합니다.</p>"
                }
              }
            },
            {
              key: :labels_delete,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/labels/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Label UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Label deleted",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Label deleted successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Delete Label",
                  content: "<p>Deletes a label definition and detaches it from all tagged conversations.</p>"
                },
                de: {
                  title: "Label löschen",
                  content: "<p>Löscht eine Label-Definition und entfernt sie von Konversationen.</p>"
                },
                es: {
                  title: "Eliminar Etiqueta",
                  content: "<p>Elimina una definición de etiqueta y la desvincula de las conversaciones.</p>"
                },
                fr: {
                  title: "Supprimer l'étiquette",
                  content: "<p>Supprime une définition d'étiquette et la détache des conversations.</p>"
                },
                "pt-BR": {
                  title: "Excluir Rótulo",
                  content: "<p>Remove uma definição de rótulo e a desvincula de todas as conversas.</p>"
                },
                ar: {
                  title: "حذف التسمية",
                  content: "<p>يحذف تعريف التسمية ويفصله عن جميع المحادثات الموسومة.</p>"
                },
                ko: {
                  title: "라벨 삭제",
                  content: "<p>라벨 정의를 삭제하고 태그된 모든 대화에서 해당 라벨을 제거합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

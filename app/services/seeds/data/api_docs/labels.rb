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
                description: "Endpoints to list and create workspace labels and color-coded tags for conversation classification."
              },
              de: {
                name: "Labels & Tags",
                description: "Endpunkte zum Auflisten und Erstellen von Labels zur Konversationsklassifizierung."
              },
              es: {
                name: "Etiquetas y Tags",
                description: "Puntos finales para listar y crear etiquetas para la clasificación de conversaciones."
              },
              fr: {
                name: "Étiquettes et Tags",
                description: "Points de terminaison pour lister et créer des étiquettes pour classer les conversations."
              },
              "pt-BR": {
                name: "Rótulos e Tags",
                description: "Endpoints para listar e criar rótulos coloridos para classificação de conversas."
              },
              ar: {
                name: "التسميات والعلامات",
                description: "نقاط النهاية لسرد وإنشاء تسميات مساحة العمل والعلامات الملونة لتصنيف المحادثات."
              },
              ko: {
                name: "라벨 및 태그",
                description: "상담 대화 분류 및 필터링을 위한 워크스페이스 라벨(태그) 목록 조회 및 생성 엔드포인트입니다."
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
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"lbl_12\",\n      \"title\": \"Bug Report\",\n      \"color\": \"#EF4444\",\n      \"description\": \"Software defects\"\n    },\n    {\n      \"id\": \"lbl_14\",\n      \"title\": \"Feature Request\",\n      \"color\": \"#3B82F6\",\n      \"description\": \"User product suggestions\"\n    }\n  ]\n}"
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
                  { "name" => "title", "type" => "string", "description" => "Label name/title", "required" => true },
                  { "name" => "color", "type" => "string", "description" => "Hex color code (e.g. '#3B82F6')", "required" => false },
                  { "name" => "description", "type" => "string", "description" => "Optional label purpose description", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Label created",
                    "body" => "{\n  \"data\": {\n    \"id\": \"lbl_15\",\n    \"title\": \"Billing Escalation\",\n    \"color\": \"#F59E0B\",\n    \"description\": \"Urgent invoice inquiries\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Label",
                  content: "<p>Creates a new label with a customizable name and color hex code for categorization.</p>"
                },
                de: {
                  title: "Label erstellen",
                  content: "<p>Erstellt ein neues Label mit anpassbarem Namen und Farbcode.</p>"
                },
                es: {
                  title: "Crear Etiqueta",
                  content: "<p>Crea una nueva etiqueta con nombre y código de color personalizables.</p>"
                },
                fr: {
                  title: "Créer une étiquette",
                  content: "<p>Crée une nouvelle étiquette avec un nom et une couleur personnalisés.</p>"
                },
                "pt-BR": {
                  title: "Criar Rótulo",
                  content: "<p>Cria um novo rótulo com nome e código de cor personalizados.</p>"
                },
                ar: {
                  title: "إنشاء تسمية جديدة",
                  content: "<p>ينشئ تسمية جديدة باسم ورمز لون قابلين للتخصيص لأغراض التصنيف.</p>"
                },
                ko: {
                  title: "라벨 생성",
                  content: "<p>대화 분류를 위해 이름과 고유 색상(Hex 코드)을 지정하여 새 라벨을 생성합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

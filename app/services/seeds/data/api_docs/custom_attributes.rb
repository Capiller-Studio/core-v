# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module CustomAttributes
        def self.category
          {
            key: :custom_attributes,
            icon_key: "sliders",
            position: 14,
            api_reference: true,
            translations: {
              en: {
                name: "Custom Attributes",
                description: "Endpoints to inspect dynamic custom field definitions for customers and conversations."
              },
              de: {
                name: "Benutzerdefinierte Attribute",
                description: "Endpunkte zum Abrufen dynamischer benutzerdefinierter Felddefinitionen."
              },
              es: {
                name: "Atributos Personalizados",
                description: "Puntos finales para inspeccionar definiciones de campos personalizados."
              },
              fr: {
                name: "Attributs Personnalisés",
                description: "Points de terminaison pour inspecter les définitions de champs personnalisés."
              },
              "pt-BR": {
                name: "Atributos Personalizados",
                description: "Endpoints para consultar definições de campos personalizados dinâmicos."
              },
              ar: {
                name: "السمات المخصصة",
                description: "نقاط النهاية لفحص تعريفات الحقول المخصصة الديناميكية للعملاء والمحادثات."
              },
              ko: {
                name: "사용자 정의 속성 (필드)",
                description: "고객 및 대화에 적용되는 동적 사용자 정의 필드 정의 목록 조회 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :custom_attributes_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/custom_attributes",
                "api_parameters" => [
                  { "name" => "entity_type", "type" => "string", "description" => "Filter by entity: 'customer' or 'conversation'", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of custom fields",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"cf_01\",\n      \"attribute_name\": \"Plan Tier\",\n      \"attribute_key\": \"plan_tier\",\n      \"attribute_type\": \"select\",\n      \"entity_type\": \"customer\",\n      \"options\": [\"Free\", \"Pro\", \"Enterprise\"]\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Custom Attribute Definitions",
                  content: "<p>Returns the schemas and option lists for dynamic custom attributes configured in the workspace.</p>"
                },
                de: {
                  title: "Benutzerdefinierte Attributdefinitionen auflisten",
                  content: "<p>Gibt Schemas und Optionslisten für benutzerdefinierte Attribute zurück.</p>"
                },
                es: {
                  title: "Listar Definiciones de Atributos Personalizados",
                  content: "<p>Devuelve esquemas y opciones para atributos personalizados.</p>"
                },
                fr: {
                  title: "Lister les définitions d'attributs personnalisés",
                  content: "<p>Renvoie les schémas et options des attributs personnalisés.</p>"
                },
                "pt-BR": {
                  title: "Listar Definições de Atributos Personalizados",
                  content: "<p>Retorna esquemas e listas de opções para atributos personalizados.</p>"
                },
                ar: {
                  title: "عرض تعريفات السمات المخصصة",
                  content: "<p>يعيد المخططات وقوائم الخيارات للسمات المخصصة التي تم تكوينها في مساحة العمل.</p>"
                },
                ko: {
                  title: "사용자 정의 필드 정의 목록 조회",
                  content: "<p>워크스페이스에 구성된 동적 사용자 정의 속성의 스키마 및 선택 옵션 목록을 반환합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

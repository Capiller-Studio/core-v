# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module CustomFields
        def self.category
          {
            key: :custom_fields,
            icon_key: "sliders",
            position: 14,
            api_reference: true,
            translations: {
              en: {
                name: "Custom Fields",
                description: "Endpoints to create, manage, and inspect dynamic custom field schemas for customers and conversations."
              },
              de: {
                name: "Benutzerdefinierte Felder",
                description: "Endpunkte zum Erstellen, Verwalten und Abrufen benutzerdefinierter Feldschemata."
              },
              es: {
                name: "Campos Personalizados",
                description: "Puntos finales para crear, administrar e inspeccionar esquemas de campos personalizados."
              },
              fr: {
                name: "Champs Personnalisés",
                description: "Points de terminaison pour créer, gérer et inspecter les schémas de champs personnalisés."
              },
              "pt-BR": {
                name: "Campos Personalizados",
                description: "Endpoints para criar, gerenciar e consultar esquemas de campos personalizados."
              },
              ar: {
                name: "الحقول المخصصة",
                description: "نقاط النهاية لإنشاء وإدارة وفحص مخططات الحقول المخصصة الديناميكية للعملاء والمحادثات."
              },
              ko: {
                name: "사용자 정의 필드",
                description: "고객 및 대화의 동적 사용자 정의 필드 스키마 생성, 조회, 수정 및 관리 API입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :custom_fields_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/custom_fields",
                "api_parameters" => [
                  { "name" => "entity_type", "type" => "string", "description" => "Filter by entity: 'customer' or 'conversation'", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page (1-100, default: 50)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of custom fields",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"cf_01\",\n      \"key\": \"plan_tier\",\n      \"label\": \"Plan Tier\",\n      \"field_type\": \"select\",\n      \"entity_type\": \"customer\",\n      \"required\": false,\n      \"options\": [\n        { \"value\": \"starter\", \"label\": \"Starter\" },\n        { \"value\": \"pro\", \"label\": \"Pro\" },\n        { \"value\": \"enterprise\", \"label\": \"Enterprise\" }\n      ],\n      \"created_at\": \"2026-08-01T10:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Custom Fields",
                  content: "<p>Returns the schemas and allowed option lists for dynamic custom fields configured in the workspace.</p>"
                },
                de: {
                  title: "Benutzerdefinierte Felder auflisten",
                  content: "<p>Gibt Schemas und Optionslisten für benutzerdefinierte Felder zurück.</p>"
                },
                es: {
                  title: "Listar Campos Personalizados",
                  content: "<p>Devuelve esquemas y opciones para campos personalizados configurados.</p>"
                },
                fr: {
                  title: "Lister les champs personnalisés",
                  content: "<p>Renvoie les schémas et options des champs personnalisés.</p>"
                },
                "pt-BR": {
                  title: "Listar Campos Personalizados",
                  content: "<p>Retorna esquemas e opções para campos personalizados configurados.</p>"
                },
                ar: {
                  title: "عرض الحقول المخصصة",
                  content: "<p>يعيد المخططات وقوائم الخيارات للحقول المخصصة في مساحة العمل.</p>"
                },
                ko: {
                  title: "사용자 정의 필드 목록 조회",
                  content: "<p>워크스페이스에 구성된 동적 사용자 정의 필드의 스키마 및 선택 옵션 목록을 반환합니다.</p>"
                }
              }
            },
            {
              key: :custom_fields_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/custom_fields",
                "api_parameters" => [
                  { "name" => "key", "type" => "string", "description" => "Machine key (lowercase alphanumeric with underscores)", "required" => true },
                  { "name" => "label", "type" => "string", "description" => "Human-readable field label", "required" => true },
                  { "name" => "entity_type", "type" => "string", "description" => "'customer' or 'conversation' (default: 'customer')", "required" => false },
                  { "name" => "field_type", "type" => "string", "description" => "Type: text, email, phone, number, textarea, select, multi_select, checkbox, file, date, url", "required" => false },
                  { "name" => "options", "type" => "array[string]", "description" => "Array of string options for select/multi_select", "required" => false },
                  { "name" => "required", "type" => "boolean", "description" => "Whether value is mandatory", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Custom field created",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"cf_02\",\n    \"key\": \"account_manager\",\n    \"label\": \"Account Manager\",\n    \"field_type\": \"text\",\n    \"entity_type\": \"customer\",\n    \"required\": false\n  },\n  \"message\": \"Custom field created successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Custom Field",
                  content: "<p>Defines a new dynamic custom field definition on customers or conversations.</p>"
                },
                de: {
                  title: "Benutzerdefiniertes Feld erstellen",
                  content: "<p>Definiert ein neues dynamisches benutzerdefiniertes Feld.</p>"
                },
                es: {
                  title: "Crear Campo Personalizado",
                  content: "<p>Define un nuevo campo personalizado dinámico.</p>"
                },
                fr: {
                  title: "Créer un champ personnalisé",
                  content: "<p>Définit un nouveau champ personnalisé dynamique.</p>"
                },
                "pt-BR": {
                  title: "Criar Campo Personalizado",
                  content: "<p>Define um novo campo personalizado dinâmico.</p>"
                },
                ar: {
                  title: "إنشاء حقل مخصص",
                  content: "<p>يحدد حقلاً مخصصًا ديناميكيًا جديدًا للعملاء أو المحادثات.</p>"
                },
                ko: {
                  title: "사용자 정의 필드 생성",
                  content: "<p>고객 또는 대화에 적용할 새로운 사용자 정의 필드를 등록합니다.</p>"
                }
              }
            },
            {
              key: :custom_fields_update,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/custom_fields/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Custom Field UUID", "required" => true },
                  { "name" => "label", "type" => "string", "description" => "Updated field label", "required" => false },
                  { "name" => "description", "type" => "string", "description" => "Help tooltip description", "required" => false },
                  { "name" => "required", "type" => "boolean", "description" => "Update mandatory status", "required" => false },
                  { "name" => "options", "type" => "array[string]", "description" => "Updated choices for select fields", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Custom field updated",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"cf_01\",\n    \"label\": \"Subscription Tier\",\n    \"required\": true\n  },\n  \"message\": \"Custom field updated successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Custom Field",
                  content: "<p>Updates the label, validation requirements, or selectable options for a custom field.</p>"
                },
                de: {
                  title: "Benutzerdefiniertes Feld aktualisieren",
                  content: "<p>Aktualisiert Beschriftung, Validierungsanforderungen oder Optionen.</p>"
                },
                es: {
                  title: "Actualizar Campo Personalizado",
                  content: "<p>Actualiza la etiqueta, validaciones u opciones del campo.</p>"
                },
                fr: {
                  title: "Mettre à jour le champ personnalisé",
                  content: "<p>Met à jour le libellé, les validations ou les options du champ.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Campo Personalizado",
                  content: "<p>Atualiza o rótulo, validações ou opções do campo.</p>"
                },
                ar: {
                  title: "تحديث الحقل المخصص",
                  content: "<p>يحدّث التسمية أو متطلبات التحقق أو الخيارات المحددة للحقل.</p>"
                },
                ko: {
                  title: "사용자 정의 필드 수정",
                  content: "<p>사용자 정의 필드의 라벨, 필수 여부, 유효성 검사 또는 선택지 목록을 수정합니다.</p>"
                }
              }
            },
            {
              key: :custom_fields_delete,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/custom_fields/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Custom Field UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Custom field deleted",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Custom field deleted successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Delete Custom Field",
                  content: "<p>Removes a custom field definition from the account.</p>"
                },
                de: {
                  title: "Benutzerdefiniertes Feld löschen",
                  content: "<p>Entfernt eine benutzerdefinierte Felddefinition.</p>"
                },
                es: {
                  title: "Eliminar Campo Personalizado",
                  content: "<p>Elimina una definición de campo personalizado.</p>"
                },
                fr: {
                  title: "Supprimer le champ personnalisé",
                  content: "<p>Supprime une définition de champ personnalisé.</p>"
                },
                "pt-BR": {
                  title: "Excluir Campo Personalizado",
                  content: "<p>Remove uma definição de campo personalizado.</p>"
                },
                ar: {
                  title: "حذف الحقل المخصص",
                  content: "<p>يحذف تعريف الحقل المخصص من الحساب.</p>"
                },
                ko: {
                  title: "사용자 정의 필드 삭제",
                  content: "<p>계정에서 해당 사용자 정의 필드 정의를 완전히 제거합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

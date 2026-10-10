# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Customers
        def self.category
          {
            key: :customers,
            icon_key: "users",
            position: 6,
            api_reference: true,
            translations: {
              en: {
                name: "Customers (Contacts)",
                description: "Endpoints to create, manage, search, and update customer profiles, conversation history, notes, and custom fields."
              },
              de: {
                name: "Kunden (Kontakte)",
                description: "Endpunkte zum Erstellen, Verwalten und Aktualisieren von Kundenprofilen, Notizen und benutzerdefinierten Feldern."
              },
              es: {
                name: "Clientes (Contactos)",
                description: "Puntos finales para crear, gestionar y actualizar perfiles de clientes, notas y campos personalizados."
              },
              fr: {
                name: "Clients (Contacts)",
                description: "Points de terminaison pour créer, gérer et mettre à jour les profils clients, notes et champs personnalisés."
              },
              "pt-BR": {
                name: "Clientes (Contatos)",
                description: "Endpoints para criar, gerenciar e atualizar perfis de clientes, notas e campos personalizados."
              },
              ar: {
                name: "العملاء (جهات الاتصال)",
                description: "نقاط النهاية لإنشاء وإدارة وتحديث ملفات تعريف العملاء، وملاحظات الفريق والحقول المخصصة."
              },
              ko: {
                name: "고객 관리 (연락처)",
                description: "고객 프로필, 상담 이력, 내부 메모 및 사용자 정의 필드를 생성, 수정 및 조회하는 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :customers_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/customers",
                "api_parameters" => [
                  { "name" => "query", "type" => "string", "description" => "Search by name, email, or phone number", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number (default: 1)", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Number of records per page (1-100, default: 20)", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Paginated list of customers",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"cst_101\",\n      \"name\": \"Alice Johnson\",\n      \"email\": \"alice@example.com\",\n      \"phone_number\": \"+15552345678\",\n      \"created_at\": \"2026-08-10T14:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 5,\n    \"total_count\": 95,\n    \"per_page\": 20\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Customers",
                  content: "<p>Returns a paginated list of customers associated with the workspace account ordered by creation date descending.</p>"
                },
                de: {
                  title: "Kunden auflisten",
                  content: "<p>Gibt eine paginierte Liste von Kunden des aktuellen Arbeitsbereichs zurück.</p>"
                },
                es: {
                  title: "Listar Clientes",
                  content: "<p>Devuelve una lista paginada de clientes asociados al espacio de trabajo actual.</p>"
                },
                fr: {
                  title: "Lister les clients",
                  content: "<p>Renvoie une liste paginée de clients associés au compte de l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Listar Clientes",
                  content: "<p>Retorna uma lista paginada de clientes associados ao espaço de trabalho.</p>"
                },
                ar: {
                  title: "عرض قائمة العملاء",
                  content: "<p>يعيد قائمة مقسمة إلى صفحات بالعملاء المرتبطين بحساب مساحة العمل الحالي.</p>"
                },
                ko: {
                  title: "고객 목록 조회",
                  content: "<p>현재 워크스페이스 계정에 등록된 고객 연락처 목록을 페이지네이션하여 반환합니다.</p>"
                }
              }
            },
            {
              key: :customers_get,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/customers/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Customer UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Customer details",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"cst_101\",\n    \"name\": \"Alice Johnson\",\n    \"first_name\": \"Alice\",\n    \"last_name\": \"Johnson\",\n    \"email\": \"alice@example.com\",\n    \"phone_number\": \"+15552345678\",\n    \"custom_attributes\": {\n      \"plan\": \"Enterprise\",\n      \"mrr\": 499\n    },\n    \"created_at\": \"2026-08-10T14:00:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Customer Details",
                  content: "<p>Retrieves complete profile information for a customer including contact details, custom fields, and timestamps.</p>"
                },
                de: {
                  title: "Kundendetails abrufen",
                  content: "<p>Ruft vollständige Profilinformationen eines Kunden einschließlich benutzerdefinierter Felder ab.</p>"
                },
                es: {
                  title: "Obtener Detalles del Cliente",
                  content: "<p>Obtiene la información de perfil completa de un cliente, incluidos los campos personalizados.</p>"
                },
                fr: {
                  title: "Obtenir les détails du client",
                  content: "<p>Récupère les informations complètes sur le profil d'un client.</p>"
                },
                "pt-BR": {
                  title: "Obter Detalhes do Cliente",
                  content: "<p>Recupera informações completas do perfil de um cliente.</p>"
                },
                ar: {
                  title: "عرض تفاصيل العميل",
                  content: "<p>يسترد معلومات الملف الشخصي الكاملة للعميل بما في ذلك الحقول المخصصة وتفاصيل الاتصال.</p>"
                },
                ko: {
                  title: "고객 상세 정보 조회",
                  content: "<p>특정 고객의 연락처, 사용자 정의 속성 및 생성일자를 포함한 상세 프로필을 조회합니다.</p>"
                }
              }
            },
            {
              key: :customers_create,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/customers",
                "api_parameters" => [
                  { "name" => "name", "type" => "string", "description" => "Full customer name", "required" => true },
                  { "name" => "email", "type" => "string", "description" => "Customer email address", "required" => false },
                  { "name" => "phone_number", "type" => "string", "description" => "E.164 formatted phone number", "required" => false },
                  { "name" => "custom_attributes", "type" => "object", "description" => "Key-value custom attributes", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 201,
                    "description" => "Customer created successfully",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"cst_102\",\n    \"name\": \"Bob Smith\",\n    \"email\": \"bob@corp.com\",\n    \"phone_number\": \"+15559876543\",\n    \"created_at\": \"2026-09-02T14:00:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Create Customer",
                  content: "<p>Creates a new customer contact record in the current workspace.</p>"
                },
                de: {
                  title: "Kunden erstellen",
                  content: "<p>Erstellt einen neuen Kundenkontakt im aktuellen Arbeitsbereich.</p>"
                },
                es: {
                  title: "Crear Cliente",
                  content: "<p>Crea un nuevo registro de contacto de cliente en el espacio de trabajo.</p>"
                },
                fr: {
                  title: "Créer un client",
                  content: "<p>Crée un nouvel enregistrement de contact client dans l'espace de travail.</p>"
                },
                "pt-BR": {
                  title: "Criar Cliente",
                  content: "<p>Cria um novo registro de cliente no espaço de trabalho.</p>"
                },
                ar: {
                  title: "إنشاء عميل جديد",
                  content: "<p>ينشئ سجل جهة اتصال عميل جديد في مساحة العمل الحالية.</p>"
                },
                ko: {
                  title: "고객 생성",
                  content: "<p>워크스페이스에 새로운 고객 연락처 레코드를 생성합니다.</p>"
                }
              }
            },
            {
              key: :customers_patch,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/customers/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Customer UUID", "required" => true },
                  { "name" => "name", "type" => "string", "description" => "Full name", "required" => false },
                  { "name" => "email", "type" => "string", "description" => "Email address", "required" => false },
                  { "name" => "phone_number", "type" => "string", "description" => "Phone number", "required" => false },
                  { "name" => "custom_attributes", "type" => "object", "description" => "JSON key-value object of custom attributes", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Customer updated",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"cst_101\",\n    \"name\": \"Alice Johnson\",\n    \"email\": \"alice.j@example.com\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Customer & Custom Fields",
                  content: "<p>Updates customer contact attributes, names, phone numbers, or custom attributes JSON payload.</p>"
                },
                de: {
                  title: "Kunden & benutzerdefinierte Felder aktualisieren",
                  content: "<p>Aktualisiert Kontaktdaten oder benutzerdefinierte Attribute eines Kunden.</p>"
                },
                es: {
                  title: "Actualizar Cliente y Campos Personalizados",
                  content: "<p>Actualiza los atributos de contacto o campos personalizados del cliente.</p>"
                },
                fr: {
                  title: "Mettre à jour le client et les champs personnalisés",
                  content: "<p>Met à jour les informations de contact ou les attributs personnalisés d'un client.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Cliente e Campos Personalizados",
                  content: "<p>Atualiza os dados de contato ou campos personalizados de um cliente.</p>"
                },
                ar: {
                  title: "تحديث العميل والحقول المخصصة",
                  content: "<p>يقوم بتحديث سمات جهة اتصال العميل، أو أرقام الهواتف، أو الحقول المخصصة.</p>"
                },
                ko: {
                  title: "고객 정보 및 사용자 정의 필드 수정",
                  content: "<p>고객 연락처 정보, 이름 및 JSON 사용자 정의 필드 데이터를 수정합니다.</p>"
                }
              }
            },
            {
              key: :customers_delete,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/customers/:id",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Customer UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Customer deleted",
                    "body" => "{\n  \"success\": true,\n  \"message\": \"Customer deleted successfully\"\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Delete Customer",
                  content: "<p>Deletes a customer profile and associated contact records.</p>"
                },
                de: {
                  title: "Kunden löschen",
                  content: "<p>Löscht ein Kundenprofil und zugehörige Kontaktdaten.</p>"
                },
                es: {
                  title: "Eliminar Cliente",
                  content: "<p>Elimina el perfil de un cliente y los registros de contacto asociados.</p>"
                },
                fr: {
                  title: "Supprimer le client",
                  content: "<p>Supprime un profil client et les enregistrements associés.</p>"
                },
                "pt-BR": {
                  title: "Excluir Cliente",
                  content: "<p>Remove o perfil de um cliente e seus dados associados.</p>"
                },
                ar: {
                  title: "حذف العميل",
                  content: "<p>يحذف ملف تعريف العميل وسجلات الاتصال المرتبطة به.</p>"
                },
                ko: {
                  title: "고객 삭제",
                  content: "<p>고객 프로필 및 관련 연락처 정보를 계정에서 삭제합니다.</p>"
                }
              }
            },
            {
              key: :customers_conversations,
              article_type: :api_endpoint,
              position: 6,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/customers/:id/conversations",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Customer UUID", "required" => true },
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Customer conversations",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"cnv_777\",\n      \"status\": \"active\",\n      \"priority\": \"medium\",\n      \"created_at\": \"2026-09-01T12:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Customer Conversation History",
                  content: "<p>Returns the full omnichannel conversation history for the specified customer.</p>"
                },
                de: {
                  title: "Kunden-Konversationsverlauf",
                  content: "<p>Gibt den vollständigen Konversationsverlauf für den Kunden zurück.</p>"
                },
                es: {
                  title: "Historial de Conversaciones del Cliente",
                  content: "<p>Devuelve el historial completo de conversaciones del cliente especificado.</p>"
                },
                fr: {
                  title: "Historique des conversations du client",
                  content: "<p>Renvoie l'historique complet des conversations pour le client spécifié.</p>"
                },
                "pt-BR": {
                  title: "Histórico de Conversas do Cliente",
                  content: "<p>Retorna o histórico completo de conversas multicanal do cliente.</p>"
                },
                ar: {
                  title: "سجل محادثات العميل",
                  content: "<p>يعيد سجل المحادثات الكامل متعدد القنوات للعميل المحدد.</p>"
                },
                ko: {
                  title: "고객 상담 대화 이력",
                  content: "<p>해당 고객의 모든 옴니채널 상담 대화 이력을 시간순으로 반환합니다.</p>"
                }
              }
            },
            {
              key: :customers_notes,
              article_type: :api_endpoint,
              position: 7,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/customers/:id/notes",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Customer UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of internal notes",
                    "body" => "{\n  \"success\": true,\n  \"data\": [\n    {\n      \"id\": \"not_01\",\n      \"content\": \"VIP client requested enterprise onboarding call next Monday.\",\n      \"user_id\": \"usr_888\",\n      \"user_name\": \"Sarah Connor\",\n      \"created_at\": \"2026-09-10T11:00:00Z\"\n    }\n  ]\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Customer Notes",
                  content: "<p>Retrieves internal CRM notes pinned to the customer profile by agents.</p>"
                },
                de: {
                  title: "Kundennotizen auflisten",
                  content: "<p>Ruft interne CRM-Notizen zum Kundenprofil ab.</p>"
                },
                es: {
                  title: "Listar Notas del Cliente",
                  content: "<p>Obtiene notas internas de CRM vinculadas al perfil del cliente.</p>"
                },
                fr: {
                  title: "Lister les notes du client",
                  content: "<p>Récupère les notes internes CRM épinglées au profil client.</p>"
                },
                "pt-BR": {
                  title: "Listar Notas do Cliente",
                  content: "<p>Consulta as notas internas de CRM vinculadas ao perfil do cliente.</p>"
                },
                ar: {
                  title: "عرض ملاحظات العميل",
                  content: "<p>يسترد ملاحظات إدارة علاقات العملاء الداخلية المثبتة في ملف تعريف العميل بواسطة الوكلاء.</p>"
                },
                ko: {
                  title: "고객 내부 메모 목록 조회",
                  content: "<p>상담원들이 고객 프로필에 작성한 내부 CRM 메모 목록을 조회합니다.</p>"
                }
              }
            },
            {
              key: :customers_create_note,
              article_type: :api_endpoint,
              position: 8,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/customers/:id/notes",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Customer UUID", "required" => true },
                  { "name" => "content", "type" => "string", "description" => "Internal note text", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Note created",
                    "body" => "{\n  \"success\": true,\n  \"data\": {\n    \"id\": \"not_02\",\n    \"content\": \"Client upgraded contract to annual billing.\",\n    \"user_name\": \"Sarah Connor\",\n    \"created_at\": \"2026-09-15T09:00:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Add Customer Note",
                  content: "<p>Appends an internal note to the customer profile for teammate collaboration.</p>"
                },
                de: {
                  title: "Kundennotiz hinzufügen",
                  content: "<p>Fügt dem Kundenprofil eine interne Notiz für das Team hinzu.</p>"
                },
                es: {
                  title: "Agregar Nota al Cliente",
                  content: "<p>Agrega una nota interna al perfil del cliente para la colaboración del equipo.</p>"
                },
                fr: {
                  title: "Ajouter une note au client",
                  content: "<p>Ajoute une note interne au profil client pour la collaboration d'équipe.</p>"
                },
                "pt-BR": {
                  title: "Adicionar Nota ao Cliente",
                  content: "<p>Adiciona uma nota interna ao perfil do cliente para colaboração da equipe.</p>"
                },
                ar: {
                  title: "إضافة ملاحظة للعميل",
                  content: "<p>يضيف ملاحظة داخلية إلى ملف تعريف العميل لتعاون الفريق.</p>"
                },
                ko: {
                  title: "고객 내부 메모 추가",
                  content: "<p>팀원 간 협업을 위해 고객 프로필에 새로운 내부 메모를 등록합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

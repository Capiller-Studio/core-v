# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Notifications
        def self.category
          {
            key: :notifications,
            icon_key: "bell",
            position: 13,
            api_reference: true,
            translations: {
              en: {
                name: "Notifications & Settings",
                description: "Endpoints to list user notifications, retrieve badge counts, mark as read, and update email/push notification preferences."
              },
              de: {
                name: "Benachrichtigungen & Einstellungen",
                description: "Endpunkte zum Verwalten von Benachrichtigungen, Zählerständen und Präferenzen."
              },
              es: {
                name: "Notificaciones y Configuración",
                description: "Puntos finales para listar notificaciones, obtener contadores, marcar como leídas y configurar preferencias."
              },
              fr: {
                name: "Notifications et Paramètres",
                description: "Points de terminaison pour lister les notifications, marquer comme lues et gérer les préférences."
              },
              "pt-BR": {
                name: "Notificações e Configurações",
                description: "Endpoints para listar notificações, contadores de não lidas, marcar como lidas e gerenciar preferências."
              },
              ar: {
                name: "الإشعارات والإعدادات",
                description: "نقاط النهاية لسرد إشعارات المستخدم، واسترداد أعداد الشارات، وتحديدها كمقروءة، وتحديث التفضيلات."
              },
              ko: {
                name: "알림 및 환경설정",
                description: "사용자 알림 내역 조회, 안 읽은 알림 개수 확인, 읽음 처리 및 이메일/푸시 알림 환경설정 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :notifications_list,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/notifications",
                "api_parameters" => [
                  { "name" => "unread", "type" => "boolean", "description" => "Filter by unread notifications only", "required" => false },
                  { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
                  { "name" => "per_page", "type" => "integer", "description" => "Records per page", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "List of notifications",
                    "body" => "{\n  \"data\": [\n    {\n      \"id\": \"ntf_501\",\n      \"notification_type\": \"conversation_assigned\",\n      \"read_at\": null,\n      \"message\": \"You were assigned to conversation #CNV-1029\",\n      \"created_at\": \"2026-09-02T14:10:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "List Notifications",
                  content: "<p>Returns a paginated list of notifications for the current authenticated user with optional unread filter.</p>"
                },
                de: {
                  title: "Benachrichtigungen auflisten",
                  content: "<p>Gibt eine paginierte Liste von Benachrichtigungen für den aktuellen Benutzer zurück.</p>"
                },
                es: {
                  title: "Listar Notificaciones",
                  content: "<p>Devuelve una lista paginada de notificaciones para el usuario autenticado.</p>"
                },
                fr: {
                  title: "Lister les notifications",
                  content: "<p>Renvoie une liste paginée de notifications pour l'utilisateur.</p>"
                },
                "pt-BR": {
                  title: "Listar Notificações",
                  content: "<p>Retorna uma lista paginada de notificações para o usuário autenticado.</p>"
                },
                ar: {
                  title: "عرض قائمة الإشعارات",
                  content: "<p>يعيد قائمة مقسمة إلى صفحات بالإشعارات للمستخدم الحالي مع دعم تصفية غير المقروءة.</p>"
                },
                ko: {
                  title: "알림 목록 조회",
                  content: "<p>현재 로그인한 사용자의 알림 목록을 페이지네이션하여 반환합니다.</p>"
                }
              }
            },
            {
              key: :notifications_unread_count,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/notifications/unread_count",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Unread count",
                    "body" => "{\n  \"data\": {\n    \"unread_count\": 3\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Unread Notification Count",
                  content: "<p>Returns the total number of unread notifications for badge rendering.</p>"
                },
                de: {
                  title: "Anzahl ungelesener Benachrichtigungen",
                  content: "<p>Gibt die Anzahl der ungelesenen Benachrichtigungen für Badge-Anzeigen zurück.</p>"
                },
                es: {
                  title: "Obtener Contador de No Leídas",
                  content: "<p>Devuelve el número total de notificaciones no leídas para insignias.</p>"
                },
                fr: {
                  title: "Obtenir le nombre de non lus",
                  content: "<p>Renvoie le nombre total de notifications non lues.</p>"
                },
                "pt-BR": {
                  title: "Obter Contagem de Não Lidas",
                  content: "<p>Retorna o número total de notificações não lidas para exibição de badges.</p>"
                },
                ar: {
                  title: "الحصول على عدد الإشعارات غير المقروءة",
                  content: "<p>يعيد العدد الإجمالي للإشعارات غير المقروءة لعرضها في شارة الإشعارات.</p>"
                },
                ko: {
                  title: "안 읽은 알림 개수 조회",
                  content: "<p>상단 배지 표시용 안 읽은 알림 총 개수를 반환합니다.</p>"
                }
              }
            },
            {
              key: :notifications_read,
              article_type: :api_endpoint,
              position: 3,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/notifications/:id/read",
                "api_parameters" => [
                  { "name" => "id", "type" => "string", "description" => "Notification UUID", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Notification marked as read",
                    "body" => "{\n  \"data\": {\n    \"id\": \"ntf_501\",\n    \"read_at\": \"2026-09-02T14:35:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Mark Notification as Read",
                  content: "<p>Marks a specific notification as read by setting the read timestamp.</p>"
                },
                de: {
                  title: "Benachrichtigung als gelesen markieren",
                  content: "<p>Markiert eine bestimmte Benachrichtigung als gelesen.</p>"
                },
                es: {
                  title: "Marcar Notificación como Leída",
                  content: "<p>Marca una notificación específica como leída.</p>"
                },
                fr: {
                  title: "Marquer la notification comme lue",
                  content: "<p>Marque une notification spécifique comme lue.</p>"
                },
                "pt-BR": {
                  title: "Marcar Notificação como Lida",
                  content: "<p>Marca uma notificação específica como lida.</p>"
                },
                ar: {
                  title: "تحديد الإشعار كمقروء",
                  content: "<p>يعين إشعارًا معينًا على أنه مقروء عن طريق تعيين الطابع الزمني للقراءة.</p>"
                },
                ko: {
                  title: "알림 읽음 처리",
                  content: "<p>특정 알림을 읽음 상태로 업데이트합니다.</p>"
                }
              }
            },
            {
              key: :notifications_read_all,
              article_type: :api_endpoint,
              position: 4,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/notifications/read_all",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "All notifications marked as read",
                    "body" => "{\n  \"data\": {\n    \"success\": true,\n    \"updated_count\": 3\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Mark All Notifications as Read",
                  content: "<p>Marks all unread notifications as read for the authenticated user in the current workspace.</p>"
                },
                de: {
                  title: "Alle Benachrichtigungen als gelesen markieren",
                  content: "<p>Markiert alle ungelesenen Benachrichtigungen des Benutzers als gelesen.</p>"
                },
                es: {
                  title: "Marcar Todas como Leídas",
                  content: "<p>Marca todas las notificaciones no leídas como leídas.</p>"
                },
                fr: {
                  title: "Tout marquer comme lu",
                  content: "<p>Marque toutes les notifications non lues comme lues.</p>"
                },
                "pt-BR": {
                  title: "Marcar Todas como Lidas",
                  content: "<p>Marca todas as notificações não lidas como lidas.</p>"
                },
                ar: {
                  title: "تحديد جميع الإشعارات كمقروءة",
                  content: "<p>يحدد جميع الإشعارات غير المقروءة كمقروءة للمستخدم الحالي في مساحة العمل.</p>"
                },
                ko: {
                  title: "모든 알림 읽음 처리",
                  content: "<p>현재 워크스페이스의 모든 안 읽은 알림을 일괄 읽음 처리합니다.</p>"
                }
              }
            },
            {
              key: :notification_settings_get,
              article_type: :api_endpoint,
              position: 5,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/notification_settings",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Current notification settings",
                    "body" => "{\n  \"data\": {\n    \"email_conversation_created\": true,\n    \"email_conversation_assigned\": true,\n    \"email_conversation_mention\": true,\n    \"push_conversation_created\": true,\n    \"push_conversation_assigned\": true,\n    \"push_conversation_mention\": true\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get Notification Settings",
                  content: "<p>Retrieves user email and push notification event delivery preferences.</p>"
                },
                de: {
                  title: "Benachrichtigungseinstellungen abrufen",
                  content: "<p>Ruft die Einstellungen für E-Mail- und Push-Benachrichtigungen ab.</p>"
                },
                es: {
                  title: "Obtener Configuración de Notificaciones",
                  content: "<p>Obtiene las preferencias de entrega de notificaciones por correo electrónico y push.</p>"
                },
                fr: {
                  title: "Obtenir les paramètres de notification",
                  content: "<p>Récupère les préférences de notification par e-mail et push.</p>"
                },
                "pt-BR": {
                  title: "Obter Configurações de Notificação",
                  content: "<p>Recupera as preferências de notificações por e-mail e push.</p>"
                },
                ar: {
                  title: "عرض إعدادات الإشعارات",
                  content: "<p>يسترد تفضيلات استلام الإشعارات عبر البريد الإلكتروني والإشعارات الفورية.</p>"
                },
                ko: {
                  title: "알림 환경설정 조회",
                  content: "<p>이메일 및 모바일 푸시 알림 수신 설정 내역을 조회합니다.</p>"
                }
              }
            },
            {
              key: :notification_settings_patch,
              article_type: :api_endpoint,
              position: 6,
              configurations: {
                "api_method" => "PATCH",
                "api_endpoint" => "/v1/notification_settings",
                "api_parameters" => [
                  { "name" => "email_conversation_created", "type" => "boolean", "description" => "Email on new conversation", "required" => false },
                  { "name" => "email_conversation_assigned", "type" => "boolean", "description" => "Email on assignment", "required" => false },
                  { "name" => "email_conversation_mention", "type" => "boolean", "description" => "Email when mentioned", "required" => false },
                  { "name" => "push_conversation_assigned", "type" => "boolean", "description" => "Push on assignment", "required" => false },
                  { "name" => "push_conversation_mention", "type" => "boolean", "description" => "Push when mentioned", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Settings updated",
                    "body" => "{\n  \"data\": {\n    \"email_conversation_created\": false,\n    \"email_conversation_assigned\": true,\n    \"push_conversation_assigned\": true\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Update Notification Settings",
                  content: "<p>Updates email and mobile push notification delivery toggles.</p>"
                },
                de: {
                  title: "Benachrichtigungseinstellungen aktualisieren",
                  content: "<p>Aktualisiert die Schalter für E-Mail- und Push-Benachrichtigungen.</p>"
                },
                es: {
                  title: "Actualizar Configuración de Notificaciones",
                  content: "<p>Actualiza los interruptores de notificación por correo electrónico y push móvil.</p>"
                },
                fr: {
                  title: "Mettre à jour les paramètres de notification",
                  content: "<p>Met à jour les préférences de notification par e-mail et mobile.</p>"
                },
                "pt-BR": {
                  title: "Atualizar Configurações de Notificação",
                  content: "<p>Atualiza as opções de recebimento de notificações por e-mail e push.</p>"
                },
                ar: {
                  title: "تحديث إعدادات الإشعارات",
                  content: "<p>يقوم بتحديث خيارات استلام الإشعارات عبر البريد الإلكتروني والإشعارات الفورية.</p>"
                },
                ko: {
                  title: "알림 환경설정 수정",
                  content: "<p>이메일 및 모바일 푸시 알림 수신 여부(새 대화, 담당자 배정, 멘션 등)를 설정합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

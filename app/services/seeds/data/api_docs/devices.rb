# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Devices
        def self.category
          {
            key: :devices,
            icon_key: "smartphone",
            position: 4,
            api_reference: true,
            translations: {
              en: {
                name: "Devices & Push Notifications",
                description: "Endpoints to register and unregister mobile devices (iOS APNS / Android FCM) and web push tokens."
              },
              de: {
                name: "Geräte & Push-Benachrichtigungen",
                description: "Endpunkte zum Registrieren und Abmelden von mobilen Geräten und Web-Push-Token."
              },
              es: {
                name: "Dispositivos y Notificaciones Push",
                description: "Puntos finales para registrar y desregistrar dispositivos móviles (iOS / Android) y tokens web push."
              },
              fr: {
                name: "Appareils et Notifications Push",
                description: "Points de terminaison pour enregistrer et désinscrire les appareils mobiles (iOS / Android) et les jetons Web Push."
              },
              "pt-BR": {
                name: "Dispositivos e Notificações Push",
                description: "Endpoints para cadastrar e remover dispositivos móveis (iOS / Android) e tokens de push web."
              },
              ar: {
                name: "الأجهزة والإشعارات الفورية",
                description: "نقاط النهاية لتسجيل وإلغاء تسجيل أجهزة الهاتف المحمول (iOS / Android) ورموز الإشعارات الفورية."
              },
              ko: {
                name: "기기 및 푸시 알림",
                description: "모바일 기기(iOS APNS / Android FCM) 및 웹 푸시 토큰 등록/해제 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :devices_create,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/devices",
                "api_parameters" => [
                  { "name" => "token", "type" => "string", "description" => "Device push token string (FCM or APNS)", "required" => true },
                  { "name" => "platform", "type" => "string", "description" => "Device platform: 'fcm', 'apns', 'ios', 'android', 'push'", "required" => false },
                  { "name" => "name", "type" => "string", "description" => "Device model / name", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Device registered successfully",
                    "body" => "{\n  \"data\": {\n    \"id\": \"dev_442\",\n    \"name\": \"iPhone 15 Pro\",\n    \"platform\": \"apns\",\n    \"created_at\": \"2026-09-02T12:00:00Z\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Register Device Token",
                  content: "<p>Registers a mobile device or web browser push token for the authenticated user to receive real-time notifications for assigned conversations and mentions.</p>"
                },
                de: {
                  title: "Geräte-Token registrieren",
                  content: "<p>Registriert ein Push-Token für mobile Geräte oder Webbrowser zum Empfang von Echtzeit-Benachrichtigungen.</p>"
                },
                es: {
                  title: "Registrar Token de Dispositivo",
                  content: "<p>Registra un token de notificación push para dispositivos móviles o navegadores web.</p>"
                },
                fr: {
                  title: "Enregistrer le jeton d'appareil",
                  content: "<p>Enregistre un jeton de notification push pour les appareils mobiles ou les navigateurs Web.</p>"
                },
                "pt-BR": {
                  title: "Registrar Token de Dispositivo",
                  content: "<p>Registra um token de notificação push para dispositivos móveis ou navegadores web.</p>"
                },
                ar: {
                  title: "تسجيل رمز الجهاز",
                  content: "<p>يسجل رمز الإشعارات الفورية لجهاز محمول أو متصفح ويب لاستلام الإشعارات المباشرة.</p>"
                },
                ko: {
                  title: "기기 푸시 토큰 등록",
                  content: "<p>대화 배정 및 멘션 알림 수신을 위해 모바일 기기(iOS/Android) 또는 웹 푸시 토큰을 등록합니다.</p>"
                }
              }
            },
            {
              key: :devices_delete,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "DELETE",
                "api_endpoint" => "/v1/devices/:token",
                "api_parameters" => [
                  { "name" => "token", "type" => "string", "description" => "Push token to unregister", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Device unregistered",
                    "body" => "{\n  \"data\": {\n    \"message\": \"Device unregistered successfully\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Unregister Device Token",
                  content: "<p>Unregisters a device push token when the user logs out or disables notifications on that device.</p>"
                },
                de: {
                  title: "Geräte-Token abmelden",
                  content: "<p>Meldet ein Push-Token ab, wenn sich der Benutzer abmeldet.</p>"
                },
                es: {
                  title: "Desregistrar Token de Dispositivo",
                  content: "<p>Desregistra un token push cuando el usuario cierra sesión.</p>"
                },
                fr: {
                  title: "Désinscrire le jeton d'appareil",
                  content: "<p>Désinscrit un jeton de notification push lors de la déconnexion.</p>"
                },
                "pt-BR": {
                  title: "Remover Token de Dispositivo",
                  content: "<p>Remove o token de notificação push quando o usuário faz logout.</p>"
                },
                ar: {
                  title: "إلغاء تسجيل رمز الجهاز",
                  content: "<p>يقوم بإلغاء تسجيل رمز الإشعار عند تسجيل خروج المستخدم من الجهاز.</p>"
                },
                ko: {
                  title: "기기 푸시 토큰 해제",
                  content: "<p>로그아웃 시 등록된 기기 푸시 토큰을 해제하여 알림 수신을 중단합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

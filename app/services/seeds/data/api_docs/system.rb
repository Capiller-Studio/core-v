# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module System
        def self.category
          {
            key: :system,
            icon_key: "server",
            position: 16,
            api_reference: true,
            translations: {
              en: {
                name: "System & Health",
                description: "System health check, versioning metadata, ActionCable WebSocket endpoints, and platform feature flags."
              },
              de: {
                name: "System & Status",
                description: "Systemstatus, Versionsmetadaten und Plattformkonfiguration."
              },
              es: {
                name: "Sistema y Estado",
                description: "Estado del sistema, metadatos de versiones y configuración de la plataforma."
              },
              fr: {
                name: "Système et Santé",
                description: "État du système, métadonnées de version et configuration de la plateforme."
              },
              "pt-BR": {
                name: "Sistema e Status",
                description: "Status do sistema, metadados de versão e configurações da plataforma."
              },
              ar: {
                name: "النظام والحالة",
                description: "فحص حالة النظام، والبيانات الوصفية للإصدار، وعناوين WebSocket وتكوين المنصة."
              },
              ko: {
                name: "시스템 및 상태",
                description: "시스템 상태 점검, API 버전 정보, 웹소켓 연결 정보 및 지원 언어 설정 조회 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :system_config,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "GET",
                "api_endpoint" => "/v1/system/config",
                "api_parameters" => [],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "System configuration details",
                    "body" => "{\n  \"data\": {\n    \"api_version\": \"1.0.0\",\n    \"supported_locales\": [\"en\", \"de\", \"es\", \"fr\", \"pt-BR\", \"ar\", \"ko\"],\n    \"default_locale\": \"en\",\n    \"action_cable_url\": \"wss://ws-rely.capiller.com\",\n    \"maintenance_mode\": false\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Get System Configuration & Health",
                  content: "<p>Returns general system operational parameters, API versioning details, supported locales, and real-time ActionCable WebSocket endpoint configurations.</p>"
                },
                de: {
                  title: "Systemkonfiguration & Status abrufen",
                  content: "<p>Gibt allgemeine Systemparameter, API-Versionen und unterstützte Sprachen zurück.</p>"
                },
                es: {
                  title: "Obtener Configuración y Estado del Sistema",
                  content: "<p>Devuelve parámetros operativos generales del sistema, versiones y configuración de WebSocket.</p>"
                },
                fr: {
                  title: "Obtenir la configuration et l'état du système",
                  content: "<p>Renvoie les paramètres opérationnels généraux du système et les versions d'API.</p>"
                },
                "pt-BR": {
                  title: "Obter Configuração e Status do Sistema",
                  content: "<p>Retorna parâmetros operacionais do sistema, versões da API e configurações de WebSocket.</p>"
                },
                ar: {
                  title: "عرض تكوين النظام والحالة",
                  content: "<p>يعيد المعلمات التشغيلية العامة للنظام، وتفاصيل إصدار واجهة برمجة التطبيقات، واللغات المدعومة.</p>"
                },
                ko: {
                  title: "시스템 구성 및 상태 확인",
                  content: "<p>시스템 운영 매개변수, API 버전, 지원 언어 목록 및 실시간 웹소켓(ActionCable) 접속 정보를 조회합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

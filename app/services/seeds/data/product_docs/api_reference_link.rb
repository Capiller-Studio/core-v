# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module ApiReferenceLink
        def self.category
          {
            key: :api_reference_portal,
            icon_key: "code",
            position: 11,
            show_in_navbar: true,
            translations: {
              en: {
                name: "API Reference",
                description: "Official REST API reference, endpoints, schemas, authentication, and developer guides."
              },
              de: {
                name: "API-Referenz",
                description: "Offizielle REST-API-Referenz, Endpunkte, Schemas und Entwicklerhandbücher."
              },
              es: {
                name: "Referencia de API",
                description: "Referencia oficial de la API REST, esquemas y guías para desarrolladores."
              },
              fr: {
                name: "Référence API",
                description: "Référence officielle de l'API REST, schémas et guides pour les développeurs."
              },
              "pt-BR": {
                name: "Referência da API",
                description: "Referência oficial da API REST, esquemas e guias de integração."
              },
              ar: {
                name: "مرجع واجهة برمجة التطبيقات (API)",
                description: "المرجع الرسمي لواجهة برمجة تطبيقات REST، والمخططات، وأدلة المطورين."
              },
              ko: {
                name: "API 레퍼런스",
                description: "공식 REST API 레퍼런스, 엔드포인트 명세, 스키마 및 개발자 가이드입니다."
              }
            }
          }
        end

        def self.articles(api_portal_domain: "developers.deskbolic.com")
          api_url = api_portal_domain.include?("localhost") ? "http://#{api_portal_domain}:3001" : "https://#{api_portal_domain}"

          [
            {
              key: :api_docs_external_link,
              article_type: :external_link,
              position: 1,
              configurations: {
                "external_url" => api_url
              },
              translations: {
                en: {
                  title: "Deskbolic REST API Documentation",
                  content: "<p>Redirecting to Deskbolic REST API Documentation...</p>"
                },
                de: {
                  title: "Deskbolic REST-API-Dokumentation",
                  content: "<p>Weiterleitung zur Deskbolic REST-API-Dokumentation...</p>"
                },
                es: {
                  title: "Documentación de la API REST de Deskbolic",
                  content: "<p>Redirigiendo a la documentación de la API REST de Deskbolic...</p>"
                },
                fr: {
                  title: "Documentation de l'API REST Deskbolic",
                  content: "<p>Redirection vers la documentation de l'API REST Deskbolic...</p>"
                },
                "pt-BR": {
                  title: "Documentação da API REST Deskbolic",
                  content: "<p>Redirecionando para a documentação da API REST Deskbolic...</p>"
                },
                ar: {
                  title: "وثائق واجهة برمجة تطبيقات Deskbolic REST",
                  content: "<p>جاري إعادة التوجيه إلى وثائق واجهة برمجة تطبيقات Deskbolic REST...</p>"
                },
                ko: {
                  title: "Deskbolic REST API 공식 설명서",
                  content: "<p>Deskbolic REST API 공식 설명서로 이동합니다...</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

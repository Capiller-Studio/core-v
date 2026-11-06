# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module UserGuideLink
        def self.category
          {
            key: :user_guide_portal,
            icon_key: "book-open",
            position: 17,
            api_reference: false,
            show_in_navbar: true,
            translations: {
              en: {
                name: "User Guide",
                description: "Customer help center, onboarding walkthroughs, feature guides, and tutorials."
              },
              de: {
                name: "Benutzerhandbuch",
                description: "Kundenhilfe-Center, Onboarding-Anleitungen und Tutorials."
              },
              es: {
                name: "Guía del Usuario",
                description: "Centro de ayuda al cliente, guías de incorporación y tutoriales."
              },
              fr: {
                name: "Guide Utilisateur",
                description: "Centre d'aide client, tutoriels d'intégration et guides d'utilisation."
              },
              "pt-BR": {
                name: "Guia do Usuário",
                description: "Central de ajuda ao cliente, tutoriais de integração e guias de uso."
              },
              ar: {
                name: "دليل المستخدم",
                description: "مركز مساعدة العملاء، وأدلة الإعداد، والبرامج التعليمية."
              },
              ko: {
                name: "사용자 가이드",
                description: "고객 헬프 센터, 온보딩 가이드 및 기능 튜토리얼입니다."
              }
            }
          }
        end

        def self.articles(help_center_domain: "help-rely.capiller.com")
          help_url = help_center_domain.include?("localhost") ? "http://#{help_center_domain}:3001" : "https://#{help_center_domain}"

          [
            {
              key: :user_guide_external_link,
              article_type: :external_link,
              position: 1,
              configurations: {
                "external_url" => help_url
              },
              translations: {
                en: {
                  title: "Capiller Rely User Guide & Knowledge Base",
                  content: "<p>Redirecting to Capiller Rely User Guide & Help Center...</p>"
                },
                de: {
                  title: "Capiller Rely Benutzerhandbuch & Wissensdatenbank",
                  content: "<p>Weiterleitung zum Capiller Rely Benutzerhandbuch...</p>"
                },
                es: {
                  title: "Guía del Usuario y Base de Conocimientos de Capiller Rely",
                  content: "<p>Redirigiendo a la Guía del Usuario de Capiller Rely...</p>"
                },
                fr: {
                  title: "Guide Utilisateur et Base de Connaissances Capiller Rely",
                  content: "<p>Redirection vers le Guide Utilisateur Capiller Rely...</p>"
                },
                "pt-BR": {
                  title: "Guia do Usuário e Base de Conhecimento Capiller Rely",
                  content: "<p>Redirecionando para a Central de Ajuda Capiller Rely...</p>"
                },
                ar: {
                  title: "دليل المستخدم وقاعدة المعرفة لمنصة Capiller Rely",
                  content: "<p>جاري إعادة التوجيه إلى دليل المستخدم ومركز المساعدة...</p>"
                },
                ko: {
                  title: "Capiller Rely 사용자 가이드 및 고객 지식 기반",
                  content: "<p>Capiller Rely 사용자 가이드 및 헬프 센터로 이동합니다...</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

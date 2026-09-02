# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module HelpCenterManagement
        def self.category
          {
            key: :help_center_management,
            icon_key: "book",
            position: 7,
            translations: {
              en: {
                name: "Knowledge Base & Help Center",
                description: "Build self-service documentation portals, manage categories and articles, enable 7-locale translations, and connect custom domains."
              },
              de: {
                name: "Wissensdatenbank & Help Center",
                description: "Erstellen Sie Self-Service-Portale, verwalten Sie mehrsprachige Artikel und benutzerdefinierte Domains."
              },
              es: {
                name: "Base de Conocimientos y Centro de Ayuda",
                description: "Cree portales de autoayuda, gestione artículos multilingües y conecte dominios personalizados."
              },
              fr: {
                name: "Base de Connaissances et Centre d'Aide",
                description: "Créez des portails en libre-service, gérez des articles multilingues et des domaines personnalisés."
              },
              "pt-BR": {
                name: "Base de Conhecimento e Central de Ajuda",
                description: "Crie portais de autoatendimento, gerencie artigos em múltiplos idiomas e conecte domínios personalizados."
              },
              ar: {
                name: "قاعدة المعرفة ومركز المساعدة",
                description: "أنشئ بوابات توثيق للخدمة الذاتية، وأدر الفئات والمقالات متعددة اللغات، واربط النطاقات المخصصة."
              },
              ko: {
                name: "지식 기반 및 헬프 센터 관리",
                description: "고객 셀프 서비스 도움말 포털 구축, 7개 언어 번역 관리, 카테고리/문서 작성 및 커스텀 도메인 연결 가이드입니다."
              }
            }
          }
        end

        def self.articles(api_portal_domain: "developers.deskbolic.com")
          api_url = "https://#{api_portal_domain}"

          [
            {
              key: :help_center_setup,
              position: 1,
              translations: {
                en: {
                  title: "Creating & Customizing Knowledge Base Portals",
                  content: <<~HTML
                    <p>Help Centers empower customers to find instant answers independently, deflecting common support requests.</p>
                    <h3>Custom Branding</h3>
                    <p>Customize primary and secondary brand colors, font typography, hero banner styles, and header logos under <strong>Settings &rarr; Help Center &rarr; Appearance</strong>.</p>
                    <h3>Multi-Language Support</h3>
                    <p>Enable any of the 7 supported languages (English, German, Spanish, French, Portuguese, Arabic, Korean). Authors can write side-by-side translations with AI-assisted translation tools.</p>
                  HTML
                },
                de: {
                  title: "Wissensportale erstellen & anpassen",
                  content: "<p>Erstellen Sie individuelle Help-Center-Portale mit eigenem Branding und mehrsprachiger Unterstützung.</p>"
                },
                es: {
                  title: "Creación y Personalización de Portales de Ayuda",
                  content: "<p>Cree portales de centro de ayuda personalizados con su propia marca y soporte multilingüe.</p>"
                },
                fr: {
                  title: "Création et Personnalisation des Portails d'Aide",
                  content: "<p>Créez des portails de centre d'aide personnalisés avec votre propre image de marque et prise en charge multilingue.</p>"
                },
                "pt-BR": {
                  title: "Criando e Personalizando Portais de Ajuda",
                  content: "<p>Crie portais de autoatendimento com a identidade da sua marca e suporte a múltiplos idiomas.</p>"
                },
                ar: {
                  title: "إنشاء وتخصيص بوابات مركز المساعدة",
                  content: "<p>أنشئ بوابات مركز مساعدة مخصصة مع هويتك التجارية ودعم كامل للغات المتعددة.</p>"
                },
                ko: {
                  title: "지식 기반 헬프 센터 포털 생성 및 맞춤 설정",
                  content: "<p>브랜드 로고, 테마 색상 및 7개 다국어 번역을 적용하여 고객을 위한 지식 기반 도움말 포털을 손쉽게 구축합니다.</p>"
                }
              }
            },
            {
              key: :api_reference_portal_link,
              position: 2,
              translations: {
                en: {
                  title: "Developer Platform & API Reference Portal",
                  content: <<~HTML
                    <p>Looking to build custom integrations, bots, or automate backend workflows? Deskbolic provides a dedicated <strong>REST API Reference Portal</strong>.</p>
                    <div style="padding: 20px; border-radius: 12px; background: #EEF2FF; border: 1px solid #C7D2FE; margin: 20px 0;">
                      <h4 style="margin: 0 0 8px 0; color: #3730A3;">Explore the Deskbolic API Reference</h4>
                      <p style="margin: 0 0 14px 0; color: #4338CA;">Access comprehensive endpoint specifications, interactive parameter tables, response schemas, and code samples across all 20 API resources.</p>
                      <a href="#{api_url}" target="_blank" rel="noopener noreferrer" style="display: inline-block; background: #4F46E5; color: #ffffff; padding: 10px 18px; border-radius: 8px; text-decoration: none; font-weight: 600;">Open API Documentation &rarr;</a>
                    </div>
                  HTML
                },
                de: {
                  title: "Entwicklerplattform & API-Referenzportal",
                  content: <<~HTML
                    <p>Möchten Sie benutzerdefinierte Integrationen oder Bots erstellen? Nutzen Sie das offizielle Deskbolic API-Referenzportal.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>API-Dokumentation öffnen &rarr;</strong></a></p>
                  HTML
                },
                es: {
                  title: "Plataforma de Desarrolladores y Portal de API",
                  content: <<~HTML
                    <p>¿Desea crear integraciones personalizadas o bots? Visite el portal oficial de referencia de la API de Deskbolic.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>Abrir Documentación de la API &rarr;</strong></a></p>
                  HTML
                },
                fr: {
                  title: "Plateforme Développeurs et Référence API",
                  content: <<~HTML
                    <p>Vous souhaitez créer des intégrations ou des bots? Consultez le portail de référence de l'API Deskbolic.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>Ouvrir la Documentation API &rarr;</strong></a></p>
                  HTML
                },
                "pt-BR": {
                  title: "Plataforma de Desenvolvedores e Referência da API",
                  content: <<~HTML
                    <p>Deseja criar integrações personalizadas ou bots? Acesse o portal oficial de referência da API Deskbolic.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>Abrir Documentação da API &rarr;</strong></a></p>
                  HTML
                },
                ar: {
                  title: "منصة المطورين ومرجع واجهة برمجة التطبيقات (API)",
                  content: <<~HTML
                    <p>هل ترغب في بناء عمليات تكامل مخصصة أو روبوتات محادثة؟ قم بزيارة بوابة مرجع واجهة برمجة تطبيقات Deskbolic الرسمية.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>فتح وثائق واجهة برمجة التطبيقات &rarr;</strong></a></p>
                  HTML
                },
                ko: {
                  title: "개발자 플랫폼 및 API 레퍼런스 포털 바로가기",
                  content: <<~HTML
                    <p>자체 서비스 연동, 챗봇 또는 백엔드 자동화를 구축하려면 Deskbolic 공식 <strong>REST API 레퍼런스 포털</strong>을 확인하세요.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>API 공식 설명서 열기 &rarr;</strong></a></p>
                  HTML
                }
              }
            }
          ]
        end
      end
    end
  end
end

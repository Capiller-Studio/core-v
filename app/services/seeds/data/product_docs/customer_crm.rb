# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module CustomerCrm
        def self.category
          {
            key: :customer_crm,
            icon_key: "users",
            position: 6,
            translations: {
              en: {
                name: "Customer CRM & Contacts",
                description: "Manage unified customer profiles, view complete interaction history, define custom fields, and segment contacts."
              },
              de: {
                name: "Kunden-CRM & Kontakte",
                description: "Verwalten Sie einheitliche Kundenprofile, Interaktionsverläufe und benutzerdefinierte Felder."
              },
              es: {
                name: "CRM de Clientes y Contactos",
                description: "Gestione perfiles de clientes unificados, historial de interacciones y campos personalizados."
              },
              fr: {
                name: "CRM Clients et Contacts",
                description: "Gérez les profils clients unifiés, l'historique des interactions et les champs personnalisés."
              },
              "pt-BR": {
                name: "CRM de Clientes e Contatos",
                description: "Gerencie perfis unificados de clientes, histórico de interações e campos personalizados."
              },
              ar: {
                name: "إدارة علاقات العملاء (CRM) وجهات الاتصال",
                description: "إدارة ملفات تعريف العملاء الموحدة، وعرض سجل التفاعل الكامل، وتحديد الحقول المخصصة."
              },
              ko: {
                name: "고객 관리 (CRM) 및 연락처",
                description: "통합 고객 프로필 관리, 이전 상담 이력 타임라인 확인, 커스텀 필드 설정 및 고객 세분화 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :customer_profiles_and_timeline,
              position: 1,
              translations: {
                en: {
                  title: "Customer Profiles & Interaction Timelines",
                  content: <<~HTML
                    <p>Deskbolic automatically unifies customer conversations across Email, Chat, and WhatsApp into a single contact record.</p>
                    <h3>Customer Sidebar in Inbox</h3>
                    <p>When viewing any conversation, the right-hand sidebar displays the customer's full profile, email addresses, phone numbers, past conversations, and custom attribute tags.</p>
                  HTML
                },
                de: {
                  title: "Kundenprofile & Interaktionsverlauf",
                  content: "<p>Deskbolic bündelt Kundenkonversationen über alle Kanäle in einem zentralen Kundenprofil.</p>"
                },
                es: {
                  title: "Perfiles de Clientes y Línea de Tiempo",
                  content: "<p>Deskbolic unifica automáticamente las conversaciones de clientes en un único registro de contacto.</p>"
                },
                fr: {
                  title: "Profils Clients et Historique des Échanges",
                  content: "<p>Deskbolic unifie automatiquement les conversations des clients dans un profil unique.</p>"
                },
                "pt-BR": {
                  title: "Perfis de Clientes e Linha do Tempo",
                  content: "<p>O Deskbolic unifica automaticamente os atendimentos de clientes em um único cadastro de contato.</p>"
                },
                ar: {
                  title: "ملفات تعريف العملاء والجدول الزمني للتفاعل",
                  content: "<p>يوحد Deskbolic تلقائيًا محادثات العملاء عبر جميع القنوات في سجل جهة اتصال واحد وشامل.</p>"
                },
                ko: {
                  title: "고객 프로필 및 상담 타임라인",
                  content: "<p>이메일, 채팅, 메신저 등 모든 채널의 대화 이력을 단일 고객 프로필로 통합하여 우측 사이드바에 실시간 표시합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end

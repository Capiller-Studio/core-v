# frozen_string_literal: true

require_relative "data/api_docs/getting_started"
require_relative "data/api_docs/authentication"
require_relative "data/api_docs/identity_and_profiles"
require_relative "data/api_docs/devices"
require_relative "data/api_docs/inboxes"
require_relative "data/api_docs/customers"
require_relative "data/api_docs/conversations"
require_relative "data/api_docs/messages"
require_relative "data/api_docs/attachments"
require_relative "data/api_docs/agents_and_teams"
require_relative "data/api_docs/labels"
require_relative "data/api_docs/canned_responses"
require_relative "data/api_docs/notifications"
require_relative "data/api_docs/custom_attributes"
require_relative "data/api_docs/searches"
require_relative "data/api_docs/system"
require_relative "data/api_docs/user_guide_link"

module Seeds
  class ApiDocumentationSeeder
    DATA_MODULES = [
      Data::ApiDocs::GettingStarted,
      Data::ApiDocs::Authentication,
      Data::ApiDocs::IdentityAndProfiles,
      Data::ApiDocs::Devices,
      Data::ApiDocs::Inboxes,
      Data::ApiDocs::Customers,
      Data::ApiDocs::Conversations,
      Data::ApiDocs::Messages,
      Data::ApiDocs::Attachments,
      Data::ApiDocs::AgentsAndTeams,
      Data::ApiDocs::Labels,
      Data::ApiDocs::CannedResponses,
      Data::ApiDocs::Notifications,
      Data::ApiDocs::CustomAttributes,
      Data::ApiDocs::Searches,
      Data::ApiDocs::System,
      Data::ApiDocs::UserGuideLink
    ].freeze

    PORTAL_TRANSLATIONS = {
      en: {
        hero_title: "Deskbolic API Reference",
        hero_subtitle: "Comprehensive REST API documentation, guides, and integration reference for Deskbolic.",
        header_tagline: "Developer Platform & API Reference",
        search_placeholder: "Search API endpoints, parameters, and guides...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. All rights reserved."
      },
      de: {
        hero_title: "Deskbolic API-Referenz",
        hero_subtitle: "Vollständige REST-API-Dokumentation, Anleitungen und Referenz für Deskbolic.",
        header_tagline: "Entwicklerplattform & API-Referenz",
        search_placeholder: "API-Endpunkte, Parameter und Anleitungen durchsuchen...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Alle Rechte vorbehalten."
      },
      es: {
        hero_title: "Referencia de la API de Deskbolic",
        hero_subtitle: "Documentación completa de la API REST, guías y referencia de integración.",
        header_tagline: "Plataforma para Desarrolladores y Referencia de API",
        search_placeholder: "Buscar puntos finales de API, parámetros y guías...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Todos los derechos reservados."
      },
      fr: {
        hero_title: "Référence de l'API Deskbolic",
        hero_subtitle: "Documentation complète de l'API REST, guides et intégrations pour Deskbolic.",
        header_tagline: "Plateforme Développeurs & Référence API",
        search_placeholder: "Rechercher des points de terminaison, paramètres et guides...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Tous droits réservés."
      },
      "pt-BR": {
        hero_title: "Referência da API Deskbolic",
        hero_subtitle: "Documentação completa da API REST, guias e integrações para Deskbolic.",
        header_tagline: "Plataforma de Desenvolvedores e Referência de API",
        search_placeholder: "Pesquisar endpoints da API, parâmetros e guias...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Todos os direitos reservados."
      },
      ar: {
        hero_title: "مرجع واجهة برمجة تطبيقات Deskbolic",
        hero_subtitle: "وثائق REST API الشاملة والأدلة والتكامل لمنصة Deskbolic.",
        header_tagline: "منصة المطورين ومرجع واجهة برمجة التطبيقات",
        search_placeholder: "البحث في نقاط نهاية واجهة برمجة التطبيقات والمعلمات...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. جميع الحقوق محفوظة."
      },
      ko: {
        hero_title: "Deskbolic API 레퍼런스",
        hero_subtitle: "Deskbolic의 종합적인 REST API 설명서, 연동 가이드 및 레퍼런스 문서입니다.",
        header_tagline: "개발자 플랫폼 및 API 레퍼런스",
        search_placeholder: "API 엔드포인트, 파라미터 및 가이드 검색...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. All rights reserved."
      }
    }.freeze

    attr_reader :account, :domain, :help_center_domain

    def self.seed(account: nil, domain: "developers.deskbolic.com", help_center_domain: "help.deskbolic.com")
      target_account = account || Account.find_by(identifier: "deskbolic") || Account.first
      unless target_account
        puts "Skipping API documentation seed: No account available."
        return
      end

      new(account: target_account, domain: domain, help_center_domain: help_center_domain).seed
    end

    def initialize(account:, domain: "developers.deskbolic.com", help_center_domain: "help.deskbolic.com")
      @account = account
      @domain = domain
      @help_center_domain = help_center_domain
    end

    def seed
      puts "Seeding Production API Documentation for account: #{account.name} on domain: #{domain}..."

      account.with_shard do
        domain_record = find_or_create_domain
        portal = find_or_create_portal(domain_record)
        seed_portal_translations(portal)

        # Clean purge of portal content to ensure zero leftover dummy/Lorem Ipsum data
        purge_portal_content!(portal)

        DATA_MODULES.each do |mod|
          seed_category_and_articles(portal, mod)
        end

        puts "✓ Successfully seeded #{DATA_MODULES.size} API categories with 7-locale translations."
      end
    end

    private

    def find_or_create_domain
      domain_record = Domain.find_or_initialize_by(value: domain)
      domain_record.account = account
      domain_record.domain_type = :custom
      domain_record.status = :active
      domain_record.dns_status = :dns_verified
      domain_record.ssl_status = :ssl_active
      domain_record.dns_verified_at = Time.current
      domain_record.save!
      domain_record
    end

    def find_or_create_portal(domain_record)
      portal = HelpCenter::Portal.find_or_initialize_by(domain_id: domain_record.id)
      portal.account = account
      portal.name = "Deskbolic API Reference"
      portal.default_locale = "en"
      portal.locales = Core::SUPPORTED_LOCALES.map(&:to_s)
      portal.status = :active
      portal.indexing_enabled = true
      portal.ui_configurations = {
        "theme_mode" => "system",
        "primary_color" => "#4f46e5",
        "secondary_color" => "#3730a3",
        "font_family" => "Inter",
        "hero_style" => "plain",
        "category_layout" => "grid"
      }
      portal.configurations = { "custom_css" => "" }
      portal.save!
      portal
    end

    def seed_portal_translations(portal)
      PORTAL_TRANSLATIONS.each do |loc, trans_data|
        t = portal.translations.find_or_initialize_by(locale: loc.to_s)
        t.hero_title = trans_data[:hero_title]
        t.hero_subtitle = trans_data[:hero_subtitle]
        t.header_tagline = trans_data[:header_tagline]
        t.search_placeholder = trans_data[:search_placeholder]
        t.footer_text = trans_data[:footer_text]
        t.save!
      end
    end

    def purge_portal_content!(portal)
      portal.articles.destroy_all
      portal.categories.destroy_all
    end

    def seed_category_and_articles(portal, mod)
      cat_def = mod.category
      articles_def = mod.respond_to?(:articles) ? (mod.method(:articles).arity != 0 ? mod.articles(help_center_domain: help_center_domain) : mod.articles) : []

      category = portal.categories.build(account: account, portal: portal)
      category.icon_key = cat_def[:icon_key]
      category.position = cat_def[:position]
      category.status = :active
      category.visibility = :everyone
      category.featured = true
      category.show_in_navbar = (cat_def[:show_in_navbar] == true || cat_def[:position].to_i <= 4)
      category.api_reference = cat_def[:api_reference] != false
      category.save!

      cat_def[:translations].each do |loc, trans|
        ct = category.translations.find_or_initialize_by(locale: loc.to_s)
        ct.name = trans[:name]
        ct.description = trans[:description]
        ct.save!
      end

      articles_def.each_with_index do |art_def, idx|
        seed_article(portal, category, art_def, idx + 1)
      end
    end

    def seed_article(portal, category, art_def, position)
      article = HelpCenter::Article.new(portal: portal, account: account)
      article.primary_category = category
      article.article_type = art_def[:article_type] || :api_endpoint
      article.status = :published
      article.visibility = :everyone
      article.position = art_def[:position] || position
      article.configurations = art_def[:configurations] || {}
      article.save!

      article.categories << category unless article.categories.exists?(id: category.id)

      art_def[:translations].each do |loc, trans|
        at = article.translations.find_or_initialize_by(locale: loc.to_s)
        at.title = trans[:title]
        at.content = trans[:content]
        at.save!
      end
    end
  end
end

# frozen_string_literal: true

require_relative "data/product_docs/getting_started"
require_relative "data/product_docs/inboxes_and_conversations"
require_relative "data/product_docs/communication_channels"
require_relative "data/product_docs/ai_agents_and_copilot"
require_relative "data/product_docs/automations_and_productivity"
require_relative "data/product_docs/customer_crm"
require_relative "data/product_docs/help_center_management"
require_relative "data/product_docs/csat_and_analytics"
require_relative "data/product_docs/security_and_roles"
require_relative "data/product_docs/billing_and_subscriptions"
require_relative "data/product_docs/api_reference_link"
require_relative "data/product_docs/teams_and_teammates"
require_relative "data/product_docs/routing_and_availability"

module Seeds
  class ProductDocumentationSeeder
    DATA_MODULES = [
      Data::ProductDocs::GettingStarted,
      Data::ProductDocs::InboxesAndConversations,
      Data::ProductDocs::CommunicationChannels,
      Data::ProductDocs::AiAgentsAndCopilot,
      Data::ProductDocs::AutomationsAndProductivity,
      Data::ProductDocs::CustomerCrm,
      Data::ProductDocs::HelpCenterManagement,
      Data::ProductDocs::CsatAndAnalytics,
      Data::ProductDocs::SecurityAndRoles,
      Data::ProductDocs::BillingAndSubscriptions,
      Data::ProductDocs::ApiReferenceLink,
      Data::ProductDocs::TeamsAndTeammates,
      Data::ProductDocs::RoutingAndAvailability
    ].freeze

    PORTAL_TRANSLATIONS = {
      en: {
        hero_title: "How can we help you today?",
        hero_subtitle: "Explore user guides, tutorials, setup walkthroughs, and answers to frequently asked questions.",
        header_tagline: "Customer Help Center & User Guide",
        search_placeholder: "Search guides, setup tutorials, and FAQs...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. All rights reserved."
      },
      de: {
        hero_title: "Wie können wir Ihnen heute helfen?",
        hero_subtitle: "Entdecken Sie Benutzerhandbücher, Einrichtungsanleitungen und Antworten auf häufig gestellte Fragen.",
        header_tagline: "Hilfe-Center & Benutzerhandbuch",
        search_placeholder: "Anleitungen, Tutorials und FAQs durchsuchen...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Alle Rechte vorbehalten."
      },
      es: {
        hero_title: "¿Cómo podemos ayudarte hoy?",
        hero_subtitle: "Explore guías de usuario, tutoriales, pasos de configuración y preguntas frecuentes.",
        header_tagline: "Centro de Ayuda y Guía del Usuario",
        search_placeholder: "Buscar guías, tutoriales y preguntas frecuentes...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Todos los derechos reservados."
      },
      fr: {
        hero_title: "Comment pouvons-nous vous aider aujourd'hui?",
        hero_subtitle: "Explorez les guides utilisateurs, tutoriels de configuration et réponses aux questions fréquentes.",
        header_tagline: "Centre d'Aide et Guide Utilisateur",
        search_placeholder: "Rechercher des guides, tutoriels et FAQ...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Tous droits réservés."
      },
      "pt-BR": {
        hero_title: "Como podemos ajudar você hoje?",
        hero_subtitle: "Explore guias do usuário, tutoriais de configuração e respostas para perguntas frequentes.",
        header_tagline: "Central de Ajuda e Guia do Usuário",
        search_placeholder: "Pesquisar guias, tutoriais e perguntas frequentes...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. Todos os direitos reservados."
      },
      ar: {
        hero_title: "كيف يمكننا مساعدتك اليوم؟",
        hero_subtitle: "استكشف أدلة المستخدم، والبرامج التعليمية للإعداد، والإجابات على الأسئلة الشائعة.",
        header_tagline: "مركز مساعدة العملاء ودليل المستخدم",
        search_placeholder: "ابحث في الأدلة، والبرامج التعليمية، والأسئلة الشائعة...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. جميع الحقوق محفوظة."
      },
      ko: {
        hero_title: "무엇을 도와드릴까요?",
        hero_subtitle: "Deskbolic 사용자 가이드, 채널 연동 튜토리얼 및 자주 묻는 질문을 확인하세요.",
        header_tagline: "고객 지원 헬프 센터 및 사용자 가이드",
        search_placeholder: "사용자 가이드, 튜토리얼 및 FAQ 검색...",
        footer_text: "© #{Time.current.year} Deskbolic Inc. All rights reserved."
      }
    }.freeze

    attr_reader :account, :domain, :api_portal_domain

    def self.seed(account: nil, domain: "help.deskbolic.com", api_portal_domain: "developers.deskbolic.com")
      target_account = account || Account.find_by(identifier: "deskbolic") || Account.first
      unless target_account
        puts "Skipping Product documentation seed: No account available."
        return
      end

      new(account: target_account, domain: domain, api_portal_domain: api_portal_domain).seed
    end

    def initialize(account:, domain: "help.deskbolic.com", api_portal_domain: "developers.deskbolic.com")
      @account = account
      @domain = domain
      @api_portal_domain = api_portal_domain
    end

    def seed
      puts "Seeding Production Product Documentation for account: #{account.name} on domain: #{domain}..."

      account.with_shard do
        domain_record = find_or_create_domain
        portal = find_or_create_portal(domain_record)
        seed_portal_translations(portal)

        HelpCenter::Portal.transaction do
          reset_portal_content!(portal)
          DATA_MODULES.each do |mod|
            seed_category_and_articles(portal, mod)
          end
        end

        puts "✓ Successfully synchronized #{DATA_MODULES.size} product documentation categories."
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
      portal.name ||= "Deskbolic User Guide & Help Center"
      portal.default_locale ||= "en"
      portal.locales = Core::SUPPORTED_LOCALES.map(&:to_s) if portal.locales.blank?
      portal.status ||= :active
      portal.indexing_enabled = true if portal.indexing_enabled.nil?
      portal.show_contact_form = true if portal.show_contact_form.nil?
      portal.ui_configurations = {
        "theme_mode" => "system",
        "primary_color" => "#2563eb",
        "secondary_color" => "#1d4ed8",
        "font_family" => "Inter",
        "hero_style" => "plain",
        "category_layout" => "grid"
      }.merge(portal.ui_configurations || {})
      portal.configurations = { "custom_css" => "" }.merge(portal.configurations || {})
      portal.save!
      portal
    end

    def seed_portal_translations(portal)
      PORTAL_TRANSLATIONS.each do |loc, trans_data|
        t = portal.translations.find_or_initialize_by(locale: loc.to_s)
        t.hero_title ||= trans_data[:hero_title]
        t.hero_subtitle ||= trans_data[:hero_subtitle]
        t.header_tagline ||= trans_data[:header_tagline]
        t.search_placeholder ||= trans_data[:search_placeholder]
        t.footer_text ||= trans_data[:footer_text]
        t.save!
      end
    end

    def reset_portal_content!(portal)
      portal.articles.find_each(&:destroy!)
      portal.categories.find_each(&:destroy!)
    end

    def seed_category_and_articles(portal, mod)
      cat_def = mod.category
      articles_def = mod.respond_to?(:articles) ? (mod.method(:articles).arity != 0 ? mod.articles(api_portal_domain: api_portal_domain) : mod.articles) : []

      category = portal.categories.build(account: account, portal: portal)
      category.icon_key = cat_def[:icon_key]
      category.position = cat_def[:position]
      category.status = :active
      category.visibility = :everyone
      # The help-center homepage only lists featured categories. The docs
      # seeder recreates categories, so preserve the product docs' historical
      # behavior and feature them unless a definition explicitly opts out.
      category.featured = cat_def.fetch(:featured, true)
      category.show_in_navbar = (cat_def[:show_in_navbar] == true || cat_def[:position].to_i <= 4)
      category.api_reference = false
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
      article.article_type = art_def[:article_type] || :standard
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

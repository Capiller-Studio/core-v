# frozen_string_literal: true

module Seeds
  class HelpCenterSeeder
    attr_reader :account

    def initialize(account:)
      @account = account
    end

    def seed
      puts "  📚 Creating help center portal..."

      portal = create_portal
      create_contact_form(portal)
      categories = create_categories(portal)
      create_articles(portal, categories)
      
      puts "    ✓ Help Center seeded successfully"
    end

    private

    def create_portal
      domain = account.domains.find_or_create_by!(value: "help.deskbolic.localhost") do |d|
        d.name = "Deskbolic Help"
        d.domain_type = :custom
        d.status = :active
        d.dns_status = :dns_verified
      end

      portal = HelpCenter::Portal.find_or_initialize_by(account: account, domain: domain)
      
      portal.name = "Techbolic Support Center"
      portal.default_locale = "en"
      portal.locales = ["en", "fr", "es"]
      portal.status = :active
      portal.show_contact_form = true
      portal.show_web_widget = true
      portal.indexing_enabled = true
      
      portal.ui_configurations = {
        "theme_mode" => "light",
        "primary_color" => "#778DFF",
        "secondary_color" => "#4F46E5",
        "font_family" => "Inter",
        "hero_style" => "plain",
        "category_layout" => "grid"
      }
      
      portal.configurations = {
        "custom_css" => ""
      }
      
      portal.save!
      portal
    end

    def create_contact_form(portal)
      # Check if portal already has a form to avoid duplicate inboxes/forms on re-seed
      form = portal.contact_form_channel
      
      unless form
        creator = Channels::ChannelCreator.new(
          channel_type: "contact_form",
          channel_params: {
            name: "Support Request Form",
            success_message_i18n_key: "contact_form.success",
            require_login: "false",
            allow_attachments: "false",
            send_confirmation_email: "false"
          },
          current_account: account
        )
        
        # We need to manually link the created form to the portal since ChannelCreator doesn't accept portal
        inbox = creator.send(:contact_form_channel)
        form = inbox.channel
        form.update!(status: :active)
        portal.update!(contact_form_channel: form)
      end

      # Create custom fields for the form
      fields = [
        { key: "full_name", field_type: :text, entity_type: :customer, mapped_to: "customer.name", configurations: { "width" => "half" }, translations: { en: "Full Name" }, required: true, position: 1 },
        { key: "email_address", field_type: :email, entity_type: :customer, mapped_to: "customer.email", configurations: { "width" => "half" }, translations: { en: "Email Address" }, required: true, position: 2 },
        { key: "subject", field_type: :text, entity_type: :conversation, mapped_to: "conversation.title", configurations: { "width" => "full" }, translations: { en: "Subject" }, required: true, position: 3 },
        { key: "category", field_type: :select, entity_type: :conversation, mapped_to: "", configurations: { "width" => "full" }, translations: { en: "Category", options: [{"label"=>"Billing", "value"=>"billing"}, {"label"=>"Technical Issue", "value"=>"tech_issue"}] }, required: true, position: 4 },
        { key: "description", field_type: :textarea, entity_type: :conversation, mapped_to: "message.content", configurations: { "width" => "full" }, translations: { en: "Description" }, required: true, position: 5 }
      ]

      fields.each do |field_data|
        cf = CustomField.find_or_initialize_by(account: account, key: field_data[:key])
        cf.field_type = field_data[:field_type]
        cf.entity_type = field_data[:entity_type]
        cf.mapped_to = field_data[:mapped_to]
        cf.configurations = field_data[:configurations]
        cf.required = field_data[:required]
        cf.save!
        
        # Link to form via resource
        CustomFieldResource.find_or_create_by!(resource: form, custom_field: cf) do |cfr|
          cfr.position = field_data[:position]
        end
        
        # Add English translation
        trans = cf.translations.find_or_initialize_by(locale: "en")
        trans.label = field_data[:translations][:en]
        trans.options = field_data[:translations][:options] if field_data[:translations][:options]
        trans.save!
      end
    end

    def create_categories(portal)
      categories = []
      
      # 1. Featured Categories (Top Level)
      cat_data = [
        { name: "Getting Started", desc: "Everything you need to set up your account and start your journey.", icon: "rocket", guide_mode: true },
        { name: "Features", desc: "Explore our robust feature set and how to maximize your productivity.", icon: "box", guide_mode: false },
        { name: "Integrations", desc: "Connect with Slack, Jira, and other essential workspace tools.", icon: "puzzle", guide_mode: false },
        { name: "Billing", desc: "Manage subscriptions, invoices, and payment methods securely.", icon: "credit-card", guide_mode: false },
        { name: "Troubleshooting", desc: "Quick fixes for common technical issues and error messages.", icon: "tool", guide_mode: false },
        { name: "FAQs", desc: "Answers to our community's most frequently asked questions.", icon: "help-circle", guide_mode: false }
      ]

      cat_data.each_with_index do |data, index|
        cat = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: data[:name] })
        cat ||= portal.categories.build(account: account)
        cat.status = :active
        cat.visibility = :everyone
        cat.icon_key = data[:icon]
        cat.position = index
        cat.featured = true
        cat.show_in_navbar = true if index < 4 # Show first 4 in navbar
        cat.guide_mode = true if data[:guide_mode]
        cat.save!
        
        create_category_translations(cat, data[:name], data[:desc])
        categories << cat
      end
      
      # 2. Bulk Random Nested Categories (30+ Categories)
      puts "    - Generating bulk random categories..."
      parent_categories = []
      
      # Generate 10 top-level random categories
      10.times do |i|
        name = FFaker::Lorem.words(rand(2..4)).join(' ').titleize
        cat = create_random_category(portal, name, nil)
        parent_categories << cat
        categories << cat
      end
      
      # Generate 20 nested categories (Level 2 & 3)
      20.times do |i|
        name = FFaker::Lorem.words(rand(2..4)).join(' ').titleize
        parent = parent_categories.sample
        cat = create_random_category(portal, name, parent)
        
        # Add a level 3 category sometimes
        if [true, false].sample
          sub_name = FFaker::Lorem.words(rand(2..3)).join(' ').titleize
          sub_cat = create_random_category(portal, sub_name, cat)
          categories << sub_cat
        end
        
        categories << cat
      end
      
      categories
    end

    def create_random_category(portal, name, parent)
      cat = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: name })
      cat ||= portal.categories.build(account: account)
      cat.status = :active
      cat.visibility = :everyone
      cat.icon_key = ["folder", "file-text", "book", "info", "settings"].sample
      cat.parent = parent if parent
      cat.save!
      
      desc = FFaker::Lorem.sentence(rand(8..15))
      create_category_translations(cat, name, desc)
      cat
    end

    def create_category_translations(category, name, desc)
      trans = category.translations.find_or_initialize_by(locale: "en")
      trans.name = name
      trans.description = desc
      trans.save!
      
      # 30% chance to have French translation
      if rand < 0.3
        trans_fr = category.translations.find_or_initialize_by(locale: "fr")
        trans_fr.name = "[FR] " + name
        trans_fr.description = "[FR] " + desc
        trans_fr.save!
      end
      
      # 20% chance to have Spanish translation
      if rand < 0.2
        trans_es = category.translations.find_or_initialize_by(locale: "es")
        trans_es.name = "[ES] " + name
        trans_es.description = "[ES] " + desc
        trans_es.save!
      end
    end

    def create_articles(portal, categories)
      puts "    - Generating articles..."
      
      # 1. Guide Mode Articles (Exactly 12 sequential for "Getting Started")
      getting_started = categories.find { |c| c.slug == "getting-started" }
      if getting_started
        12.times do |i|
          title = "Step #{i+1}: #{FFaker::Lorem.words(3).join(' ').titleize}"
          create_article(portal, getting_started, title, i)
        end
      end
      
      # 2. Pagination Testing Articles (45+ for "Features")
      features_cat = categories.find { |c| c.slug == "features" }
      if features_cat
        50.times do |i|
          title = "Feature Details: #{FFaker::Lorem.words(rand(3..6)).join(' ').titleize}"
          create_article(portal, features_cat, title, i)
        end
      end
      
      # 3. Spread random articles across other categories
      other_categories = categories - [getting_started, features_cat]
      
      100.times do |i|
        cat = other_categories.sample
        title = FFaker::Lorem.sentence(rand(4..8)).delete('.')
        create_article(portal, cat, title, i)
      end
      
      # 4. Create Related Resources
      puts "    - Linking related articles..."
      all_articles = portal.articles.to_a
      all_articles.sample(20).each do |article|
        related_articles = (all_articles - [article]).sample(rand(2..5))
        related_articles.each_with_index do |related_art, idx|
          HelpCenter::RelatedResource.find_or_create_by!(
            resource: article,
            linked_resource: related_art
          )
        end
      end
    end

    def create_article(portal, category, title, position)
      # To keep it somewhat idempotent without permalink, we search by position and category
      article = nil
      if category.articles.where(position: position).exists?
        article = category.articles.find_by(position: position)
      else
        article = portal.articles.new(account: account)
      end
      
      article.article_type = :standard
      article.status = :published
      article.visibility = :everyone
      article.views_count = rand(10..5000)
      article.position = position
      article.primary_category_id = category.id
      article.save!
      
      # English Translation
      trans = article.translations.find_or_initialize_by(locale: "en")
      trans.title = title
      
      content_blocks = rand(2..5).times.map do
        "<h2>#{FFaker::Lorem.phrase}</h2><p>#{FFaker::Lorem.paragraphs(rand(2..4)).join('</p><p>')}</p>"
      end
      trans.content = content_blocks.join("\n")
      trans.save!
      
      # French Translation (25% chance)
      if rand < 0.25
        trans_fr = article.translations.find_or_initialize_by(locale: "fr")
        trans_fr.title = "[FR] " + title
        trans_fr.content = "<p>[French Translation] #{FFaker::Lorem.paragraphs(2).join('</p><p>')}</p>"
        trans_fr.save!
      end
      
      # Spanish Translation (25% chance)
      if rand < 0.25
        trans_es = article.translations.find_or_initialize_by(locale: "es")
        trans_es.title = "[ES] " + title
        trans_es.content = "<p>[Spanish Translation] #{FFaker::Lorem.paragraphs(2).join('</p><p>')}</p>"
        trans_es.save!
      end
      
      # Link article to category
      HelpCenter::CategoryResource.find_or_create_by!(
        category: category,
        resource: article
      )
    end
  end
end

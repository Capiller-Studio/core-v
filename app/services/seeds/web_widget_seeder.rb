# frozen_string_literal: true

module Seeds
  class WebWidgetSeeder
    def self.seed
      new.seed
    end

    def seed
      puts "🔧 Seeding Web Widget test data..."

      account = find_or_create_account
      users   = find_or_create_agents(account)
      widget  = create_web_widget(account)
      inbox   = create_inbox(account, widget, users)
      portal  = create_portal(account, widget)
      create_help_center_data(account, portal)
      customer = create_test_customer(account, inbox)
      create_test_conversation(account, inbox, customer, users.first)

      print_summary(account, widget, inbox, customer)
    end

    private

    def find_or_create_account
      Account.first || Account.create!(name: "Deskbolic Demo")
    end

    FIRST_NAMES = %w[Sarah James].freeze
    LAST_NAMES = %w[Miller Chen].freeze

    def find_or_create_agents(account)
      existing = account.users
      return existing.to_a if existing.count >= 2

      agent_role = account.roles.find_by(name: "Agent")

      2.times.filter_map do |i|
        email = "agent#{i + 1}@deskbolic.test"
        user = User.find_by(email: email)
        next user if user

        user = User.create!(
          email: email,
          password: "password123",
          first_name: FIRST_NAMES[i],
          last_name: LAST_NAMES[i],
          address: Address.create!
        )

        # Attach a random avatar
        avatar_url = "https://i.pravatar.cc/256?u=agent#{i + 1}@deskbolic.test"
        ::Utilities::ActiveStorageDownloader.attach(
          record: user,
          attachment_name: :avatar,
          url: avatar_url
        )

        account_user = AccountUser.find_or_create_by!(
          account: account,
          user: user,
          availability: :online
        )

        # Assign the Agent role
        if agent_role
          Access::AccountUserRole.find_or_create_by!(
            account: account,
            account_user_id: account_user.id,
            role: agent_role
          )
        end

        user
      end
    end

    def create_web_widget(account)
      widget = Channel::WebWidget.find_or_initialize_by(account: account, name: "Demo Widget")
      widget.assign_attributes(
        website_url: "http://localhost:3000",
        ui_configurations: {
          "theme_color" => "#778DFF",
          "welcome_title" => "Welcome to Deskbolic!",
          "welcome_tagline" => "We typically reply within a few minutes.",
          "position" => "right"
        },
        configurations: {
          "default_locale" => "en"
        }
      )
      widget.save!
      widget
    end

    def create_inbox(account, widget, users)
      inbox = Inbox.find_or_initialize_by(channel: widget, account: account)
      inbox.assign_attributes(
        name: "Web Widget Inbox",
        channel_type: "Channel::WebWidget",
        configurations: { "auto_assign" => true }
      )
      inbox.save!

      # Assign agents to the inbox
      users.each do |user|
        InboxUser.find_or_create_by!(inbox: inbox, user: user)
      end

      inbox
    end

    def create_portal(account, widget)
      domain = Domain.find_or_create_by!(
        name: "help.deskbolic.test",
        value: "help.deskbolic.test",
        account: account
      )

      portal = HelpCenter::Portal.find_or_initialize_by(account: account, name: "Demo Portal")
      portal.assign_attributes(
        domain: domain,
        default_locale: "en",
        locales: [ "en", "de" ]
      )
      portal.save!

      # Link portal to widget
      widget.update!(portal: portal)

      portal
    end

    def create_help_center_data(account, portal)
      categories_data = [
        {
          name: "Getting Started",
          description: "Learn the basics of using our platform.",
          articles: [
            { slug: "how-to-get-started", title: "How to Get Started", content: "Welcome to Deskbolic! This guide will walk you through setting up your workspace and connecting your first channel." },
            { slug: "creating-your-account", title: "Creating Your Account", content: "To create an account, visit our sign-up page and enter your business email. You'll receive a verification email within minutes." },
            { slug: "connecting-your-first-channel", title: "Connecting Your First Channel", content: "Navigate to Settings > Channels and choose from Email, Live Chat, Facebook, WhatsApp, or other supported channels." }
          ]
        },
        {
          name: "Managing Conversations",
          description: "Tips for handling customer conversations efficiently.",
          articles: [
            { slug: "assigning-conversations", title: "Assigning Conversations", content: "Conversations can be assigned manually or automatically using round-robin. Go to Settings > Assignment to configure." },
            { slug: "using-canned-responses", title: "Using Canned Responses", content: "Save time by creating canned responses for frequently asked questions. Access them by typing / in the reply box." }
          ]
        },
        {
          name: "Account & Billing",
          description: "Manage your subscription, invoices, and payment methods.",
          articles: [
            { slug: "upgrading-your-plan", title: "Upgrading Your Plan", content: "To upgrade, navigate to Settings > Billing and select a plan that fits your team size and feature needs." },
            { slug: "understanding-your-invoice", title: "Understanding Your Invoice", content: "Each invoice includes a breakdown of per-agent charges, add-on fees, and any applicable taxes." }
          ]
        }
      ]

      categories_data.each_with_index do |cat_data, index|
        category = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: cat_data[:name] })
        category ||= portal.categories.build(account: account)
        category.assign_attributes(status: :active, position: index)
        category.save!

        unless category.translated_to?(:en)
          category.translations.create!(locale: "en", name: cat_data[:name], description: cat_data[:description])
        end

        cat_data[:articles].each do |art_data|
          # slug now lives on ArticleTranslation (locale-specific SEO URLs),
          # so we look up via the translation join instead of directly on the article.
          existing_translation = HelpCenter::ArticleTranslation.find_by(
            slug: art_data[:slug], locale: "en"
          )

          article = if existing_translation
                      existing_translation.article
          else
                      new_article = HelpCenter::Article.create!(
                        portal: portal, account: account, status: :published
                      )
                      new_article.translations.create!(
                        locale: "en",
                        title: art_data[:title],
                        slug: art_data[:slug],
                        content: art_data[:content]
                      )
                      new_article
          end

          # Link article to category
          HelpCenter::CategoryResource.find_or_create_by!(
            category: category,
            resource: article
          )
        end
      end
    end

    def create_test_customer(account, inbox)
      customer = Customers::CustomerCreator.call(
        account: account,
        inbox: inbox,
        external_id: "test-customer-001",
        email: "customer@example.com",
        params: {
          first_name: "Jane",
          last_name: "Doe"
        }
      )

      customer
    end

    def create_test_conversation(account, inbox, customer, agent)
      conversation = account.conversations.find_or_create_by!(
        inbox: inbox,
        source: :web_widget,
        identifier: "seed-web-widget-conv-001"
      ) do |conv|
        conv.data = {}
      end

      # Link customer as member
      conversation.conversation_members.find_or_create_by!(
        member: customer,
        account: account
      )

      # Create sample messages
      if conversation.messages.empty?
        conversation.messages.create!(
          account: account,
          inbox: inbox,
          sender: customer,
          content: "Hi, I need help setting up my account.",
          source: :web_widget,
          data: {}
        )

        conversation.messages.create!(
          account: account,
          inbox: inbox,
          sender: agent,
          content: "Hello Jane! I'd be happy to help. What would you like to set up first?",
          source: :web_widget,
          data: {}
        )
      end
    end

    def print_summary(account, widget, inbox, customer)
      puts ""
      puts "✅ Web Widget seed data created:"
      puts "   Account:     #{account.name} (#{account.id})"
      puts "   Widget:      #{widget.name} (#{widget.id})"
      puts "   HMAC Secret: #{widget.secret}"
      puts "   Inbox:       #{inbox.name} (#{inbox.id})"
      puts "   Customer:    #{customer.email} (#{customer.id})"
      puts ""
      puts "📋 Embed script URL:"
      puts "   <script src=\"http://localhost:3001/#{account.id}/#{widget.id}/embed.js\""
      puts "     data-identifier=\"test-customer-001\""
      puts "     data-signature=\"#{OpenSSL::HMAC.hexdigest('sha256', widget.secret, 'test-customer-001')}\""
      puts "     data-email=\"customer@example.com\""
      puts "     data-name=\"Jane Doe\">"
      puts "   </script>"
      puts ""
    end
  end
end

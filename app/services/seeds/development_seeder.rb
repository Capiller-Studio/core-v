# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Seeds
  class DevelopmentSeeder
    def self.seed
      new.seed
    end

    def seed
      puts "\n🌱 Seeding development environment...\n"

      account, owner = create_account_with_owner
      admin = create_admin(account, owner)
      agents = create_agents(account, owner)
      inbox = create_web_widget(account, agents + [admin])
      email_inbox = create_email_channel(account)
      teams = create_teams(account, agents, [inbox, email_inbox].compact)
      labels = create_labels(account)
      customers = create_customers(account, inbox)
      create_sample_conversations(account, inbox, customers, agents, teams)
      create_sample_automation(account)
      create_sample_macro(account)
      create_team_macro(account, teams)
      
      Seeds::HelpCenterSeeder.new(account: account).seed

      print_summary(account, owner, admin, agents, teams, inbox, email_inbox, labels, customers)
    end

    private

    # --- Account & Owner ---

    def create_account_with_owner
      puts "  📦 Creating account and owner..."

      result = Accounts::RegistrationService.call(
        email: "owner@deskbolic.test",
        password: "password123",
        first_name: "Alex",
        last_name: "Morgan",
        account_name: "Deskbolic Demo"
      )

      unless result.success?
        # Account may already exist
        user = User.find_by(email: "owner@deskbolic.test")
        account = user&.accounts&.first
        if user && account
          puts "    ✓ Already exists"
          enable_all_features!(account)
          return [account, user]
        end
        raise "Registration failed: #{result.errors.inspect}"
      end

      account = result.account
      enable_all_features!(account)
      assign_billing_defaults!(account)

      puts "    ✓ Account: #{account.name} (#{account.identifier})"
      puts "    ✓ Owner:   #{result.user.email}"

      [account, result.user]
    end

    def assign_billing_defaults!(account)
      plan = Plan.find_by!(name: Plan::ANABOLIC, currency: account.currency)
      
      unless account.subscribed?
        Billing::SubscriptionCreator.call(account: account, plan: plan, quantity: 5)
      end

      # Add $50.00 to the wallet
      unless account.wallet.balance >= 50.0
        account.wallet.credit!(50.0, description: "Initial seeder credit")
      end
    end

    def enable_all_features!(account)
      account.update!(
        api_access_enabled: true,
        sla_enabled: true,
        audit_logs_enabled: true,
        teams_enabled: true,
        automations_enabled: true,
        csat_enabled: true,
        custom_branding_enabled: true,
        contact_form_enabled: true,
        help_center_enabled: true,
        custom_email_templates_enabled: true
      )
    end

    # --- Admin ---

    def create_admin(account, invited_by)
      puts "  👤 Creating admin..."

      user = find_or_create_user(
        email: "admin@deskbolic.test",
        first_name: "Jordan",
        last_name: "Blake"
      )

      account_user = AccountUser.find_or_create_by!(account: account, user: user) do |au|
        au.availability = :online
        au.invited_by = invited_by
      end

      assign_role!(account, account_user, "administrator")
      puts "    ✓ Admin: #{user.email}"
      user
    end

    # --- Agents ---

    AGENTS = [
      { email: "agent1@deskbolic.test", first_name: "Sarah", last_name: "Miller" },
      { email: "agent2@deskbolic.test", first_name: "James", last_name: "Chen" },
      { email: "agent3@deskbolic.test", first_name: "Maria", last_name: "Garcia" }
    ].freeze

    def create_agents(account, invited_by)
      puts "  👥 Creating agents..."

      AGENTS.map do |agent_data|
        user = find_or_create_user(**agent_data)

        account_user = AccountUser.find_or_create_by!(account: account, user: user) do |au|
          au.availability = :online
          au.invited_by = invited_by
        end

        assign_role!(account, account_user, "agent")
        puts "    ✓ Agent: #{user.email}"
        user
      end
    end

    # --- Teams ---

    def create_teams(account, agents, inboxes)
      puts "  🏢 Creating teams..."

      support_team = account.teams.find_or_create_by!(name: "Support") do |t|
        t.description = "Front-line customer support team"
        t.configurations = { "assignment_policy" => "round_robin" }
      end

      engineering_team = account.teams.find_or_create_by!(name: "Engineering") do |t|
        t.description = "Technical escalation team"
        t.configurations = { "assignment_policy" => "round_robin", "max_conversations_per_agent" => 10 }
      end

      # Assign agents to teams with roles
      agents[0..1].each_with_index do |agent, idx|
        tu = TeamUser.find_or_create_by!(team: support_team, user: agent)
        tu.update!(role: :lead) if idx == 0 # First agent is team lead
      end

      agents[1..2].each_with_index do |agent, idx|
        tu = TeamUser.find_or_create_by!(team: engineering_team, user: agent)
        tu.update!(role: :lead) if idx == 0
      end

      puts "    ✓ Support (#{support_team.team_users.count} members, lead: #{support_team.lead&.display_name})"
      puts "    ✓ Engineering (#{engineering_team.team_users.count} members, lead: #{engineering_team.lead&.display_name})"

      # Link teams to inboxes
      inboxes.each do |inbox|
        InboxTeam.find_or_create_by!(inbox: inbox, team: support_team)
        InboxTeam.find_or_create_by!(inbox: inbox, team: engineering_team)
      end
      puts "    ✓ Teams linked to #{inboxes.count} inboxes"

      [support_team, engineering_team]
    end

    # --- Web Widget Channel ---

    def create_web_widget(account, users)
      puts "  💬 Creating web widget channel..."

      existing = Channel::WebWidget.find_by(account: account, name: "Demo Widget")
      if existing
        inbox = existing.primary_inbox
        puts "    ✓ Already exists → Inbox: #{inbox&.name}"
        return inbox
      end

      Channels::ChannelCreator.call(
        channel_type: "web_widget",
        channel_params: {
          name: "Demo Widget",
          website_url: "http://localhost:3000",
          ui_configurations: {
            "theme_color" => "#4f46e5",
            "welcome_title" => "Welcome to Deskbolic!",
            "welcome_tagline" => "We typically reply within a few minutes.",
            "position" => "right"
          },
          configurations: { "default_locale" => "en" }
        },
        current_account: account
      )

      inbox = Channel::WebWidget.find_by(account: account, name: "Demo Widget")&.inboxes&.first

      # Assign agents to inbox
      users.each do |user|
        InboxUser.find_or_create_by!(inbox: inbox, user: user)
      end

      puts "    ✓ Widget: Demo Widget → Inbox: #{inbox&.name}"
      inbox
    end

    # --- Email Channel ---

    def create_email_channel(account)
      puts "  ✉️  Creating email channel..."

      existing = Channel::Email.find_by(account: account, email: "support@deskbolic.test")
      if existing
        inbox = existing.primary_inbox
        puts "    ✓ Already exists → Inbox: #{inbox&.name}"
        return inbox
      end

      Channels::ChannelCreator.call(
        channel_type: "email",
        channel_params: {
          name: "Email Support",
          email: "support@deskbolic.test"
        },
        current_account: account
      )

      inbox = Channel::Email.find_by(account: account, email: "support@deskbolic.test")&.inboxes&.first
      puts "    ✓ Email: support@deskbolic.test → Inbox: #{inbox&.name}"
      inbox
    end

    # --- Labels ---

    LABEL_NAMES = %w[bug feature-request billing vip urgent].freeze

    def create_labels(account)
      puts "  🏷  Creating labels..."

      labels = LABEL_NAMES.map do |name|
        account.labels.find_or_create_by!(title: name)
      end

      puts "    ✓ #{labels.count} labels: #{LABEL_NAMES.join(', ')}"
      labels
    end

    # --- Customers ---

    CUSTOMERS = [
      { email: "jane.doe@example.com", first_name: "Jane", last_name: "Doe", external_id: "cust-001" },
      { email: "john.smith@example.com", first_name: "John", last_name: "Smith", external_id: "cust-002" },
      { email: "emily.wong@example.com", first_name: "Emily", last_name: "Wong", external_id: "cust-003" }
    ].freeze

    def create_customers(account, inbox)
      puts "  👤 Creating customers..."

      CUSTOMERS.map do |data|
        customer = Customers::CustomerCreator.call(
          account: account,
          inbox: inbox,
          external_id: data[:external_id],
          email: data[:email],
          params: { first_name: data[:first_name], last_name: data[:last_name] }
        )

        puts "    ✓ Customer: #{data[:email]}"
        customer
      end
    end

    # --- Sample Conversations ---

    def create_sample_conversations(account, inbox, customers, agents, teams)
      puts "  💬 Creating sample conversations..."

      conversations_data = [
        {
          customer: customers[0],
          agent: agents[0],
          team: teams[0],
          identifier: "seed-conv-001",
          messages: [
            { sender: :customer, content: "Hi, I need help setting up my account." },
            { sender: :agent, content: "Hello Jane! I'd be happy to help. What would you like to set up first?" },
            { sender: :customer, content: "I want to connect my email inbox." }
          ]
        },
        {
          customer: customers[1],
          agent: agents[1],
          team: teams[1],
          identifier: "seed-conv-002",
          messages: [
            { sender: :customer, content: "The dashboard is loading slowly. Is there an issue?" },
            { sender: :agent, content: "Let me check our system status. Can you share your browser and OS details?" }
          ]
        },
        {
          customer: customers[2],
          agent: nil,
          team: nil,
          identifier: "seed-conv-003",
          messages: [
            { sender: :customer, content: "I'd like to request a new feature: dark mode for the widget!" }
          ]
        }
      ]

      conversations_data.each do |conv_data|
        conversation = account.conversations.find_or_create_by!(
          inbox: inbox,
          source: :web_widget,
          identifier: conv_data[:identifier]
        ) { |c| c.data = {} }

        # Assign team if present
        if conv_data[:team] && conversation.team_id.nil?
          conversation.update!(team: conv_data[:team])
        end

        # Link customer
        conversation.conversation_members.find_or_create_by!(
          member: conv_data[:customer],
          account: account
        )

        next if conversation.messages.any?

        conv_data[:messages].each do |msg|
          sender = msg[:sender] == :customer ? conv_data[:customer] : conv_data[:agent]
          next unless sender

          conversation.messages.create!(
            account: account,
            inbox: inbox,
            sender: sender,
            content: msg[:content],
            source: :web_widget,
            data: {}
          )
        end
      end

      puts "    ✓ #{conversations_data.count} conversations created"
    end

    # --- Sample Automation ---

    def create_sample_automation(account)
      puts "  ⚡ Creating sample automation..."

      account.automations.find_or_create_by!(
        name: "Auto-assign VIP conversations"
      ) do |a|
        a.automation_type = :event_trigger
        a.event_name = "conversation.created"
        a.status = :active
        a.conditions = {
          "operator" => "AND",
          "groups" => [
            {
              "operator" => "AND",
              "conditions" => [
                { "attribute" => "customer.email", "operator" => "contains", "value" => "vip" }
              ]
            }
          ]
        }
        a.actions = [
          { "action" => "set_priority", "params" => { "priority" => "urgent" } },
          { "action" => "add_note", "params" => { "content" => "VIP customer — prioritize this conversation." } }
        ]
      end

      puts "    ✓ Automation: Auto-assign VIP conversations"
    end

    # --- Sample Macro ---

    def create_sample_macro(account)
      puts "  🎯 Creating sample macro..."

      account.macros.find_or_create_by!(name: "Close & Thank") do |m|
        m.visibility = :account_wide
        m.status = :active
        m.actions = [
          { "action" => "send_message", "params" => { "content" => "Thank you for contacting us! We're glad we could help. Feel free to reach out anytime." } },
          { "action" => "resolve", "params" => {} }
        ]
      end

      puts "    ✓ Macro: Close & Thank"
    end

    # --- Team Macro ---

    def create_team_macro(account, teams)
      return if teams.blank?

      puts "  🏢 Creating team macro..."

      account.macros.find_or_create_by!(
        name: "Escalate to Engineering",
        scopeable_type: "Team",
        scopeable_id: teams[1]&.id
      ) do |m|
        m.visibility = :team
        m.status = :active
        m.actions = [
          { "action" => "set_priority", "params" => { "priority" => "high" } },
          { "action" => "add_note", "params" => { "content" => "Escalated to Engineering team for investigation." } }
        ]
      end

      puts "    ✓ Macro: Escalate to Engineering (team-scoped)"
    end

    # --- Helpers ---

    def find_or_create_user(email:, first_name:, last_name:)
      User.find_by(email: email) || User.create!(
        email: email,
        password: "password123",
        first_name: first_name,
        last_name: last_name,
        address: Address.create!,
        confirmed_at: Time.current
      )
    end

    def assign_role!(account, account_user, identifier)
      role = account.roles.find_by(identifier: identifier)
      return unless role

      Access::AccountUserRole.find_or_create_by!(
        account: account,
        account_user_id: account_user.id,
        role: role
      )
    end

    # --- Summary ---

    def print_summary(account, owner, admin, agents, teams, inbox, email_inbox, labels, customers)
      puts "\n" + "=" * 60
      puts "✅ Development seed complete!"
      puts "=" * 60
      puts ""
      puts "  Account:    #{account.name} (#{account.identifier})"
      puts "  Shard:      #{account.shard_key}"
      puts ""
      puts "  👤 Users:"
      puts "     Owner: #{owner.email}  (password: password123)"
      puts "     Admin: #{admin.email}  (password: password123)"
      agents.each { |a| puts "     Agent: #{a.email}  (password: password123)" }
      puts ""
      puts "  🏢 Teams: #{teams.map(&:name).join(', ')}"
      puts "  📬 Inboxes: #{[inbox&.name, email_inbox&.name].compact.join(', ')}"
      puts "  🏷  Labels: #{labels.map(&:title).join(', ')}"
      puts "  👥 Customers: #{customers.count}"
      puts ""
      puts "=" * 60
      puts ""
    end
  end
end

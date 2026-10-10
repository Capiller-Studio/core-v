# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
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
      staff_users = ([owner, admin] + agents).uniq

      inboxes = create_all_inboxes(account, staff_users)
      teams = create_teams(account, agents, admin, inboxes.values)
      labels_by_name = create_labels(account)
      sla_policy = create_sla_policy(account, inboxes.values)
      customers_by_email = create_customers(account, inboxes)

      create_sample_conversations(
        account: account,
        inboxes: inboxes,
        customers: customers_by_email,
        staff: { owner: owner, admin: admin, agent1: agents[0], agent2: agents[1], agent3: agents[2] },
        teams: { support: teams[0], engineering: teams[1], sales: teams[2] },
        labels: labels_by_name,
        sla_policy: sla_policy
      )

      create_sample_automation(account)
      create_sample_macro(account)
      create_team_macro(account, teams)

      print_summary(account, owner, admin, agents, teams, inboxes.values, labels_by_name.values, customers_by_email.values)
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
        user = User.find_by(email: "owner@deskbolic.test")
        account = user&.accounts&.first
        if user && account
          puts "    ✓ Already exists"
          assign_billing_defaults!(account)
          return [account, user]
        end
        raise("Registration failed: #{result.errors.inspect}")
      end

      account = result.account
      assign_billing_defaults!(account)

      puts "    ✓ Account: #{account.name} (#{account.identifier})"
      puts "    ✓ Owner:   #{result.user.email}"

      [account, result.user]
    end

    def assign_billing_defaults!(account)
      plan = Plan.find_by!(name: Plan::HYPERBOLIC, currency: account.currency)

      if account.active_subscription.present?
        account.active_subscription.update!(plan: plan)
      else
        Billing::SubscriptionCreator.call(account: account, plan: plan, quantity: 5)
      end

      # Add $50.00 to the wallet
      unless account.wallet.balance >= 50.0
        account.wallet.credit!(50.0, description: "Initial seeder credit")
      end
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
        puts "    ✓ Agent: #{user.email} (#{user.display_name})"
        user
      end
    end

    # --- Channels & Inboxes ---

    def create_all_inboxes(account, staff_users)
      puts "  📬 Creating multi-channel inboxes..."

      inboxes = {}
      inboxes[:web_widget]   = create_web_widget(account, staff_users)
      inboxes[:email]        = create_email_channel(account, staff_users)
      inboxes[:whatsapp]     = create_whatsapp_channel(account, staff_users)
      inboxes[:facebook]     = create_facebook_channel(account, staff_users)
      inboxes[:instagram]    = create_instagram_channel(account, staff_users)
      inboxes[:contact_form] = create_contact_form_channel(account, staff_users)

      inboxes
    end

    def create_web_widget(account, staff_users)
      existing = Channel::WebWidget.find_by(account: account, name: "Demo Widget") ||
                 Channel::WebWidget.find_by(account: account, name: "Live Chat Widget")
      inbox = if existing
        existing.primary_inbox || existing.inboxes.first
      else
        Channels::ChannelCreator.call(
          channel_type: "web_widget",
          channel_params: {
            name: "Live Chat Widget",
            allowed_hosts: ["http://localhost:3000", "http://127.0.0.1:3000"],
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
        Channel::WebWidget.find_by(account: account, name: "Live Chat Widget")&.inboxes&.first
      end

      assign_staff_to_inbox(inbox, staff_users)
      puts "    ✓ Web Widget: #{inbox&.name}"
      inbox
    end

    def create_email_channel(account, staff_users)
      existing = Channel::Email.find_by(account: account, email: "support@deskbolic.test")
      inbox = if existing
        existing.primary_inbox || existing.inboxes.first
      else
        Channels::ChannelCreator.call(
          channel_type: "email",
          channel_params: {
            name: "Email Support",
            email: "support@deskbolic.test"
          },
          current_account: account
        )
        Channel::Email.find_by(account: account, email: "support@deskbolic.test")&.inboxes&.first
      end

      assign_staff_to_inbox(inbox, staff_users)
      puts "    ✓ Email: #{inbox&.name}"
      inbox
    end

    def create_whatsapp_channel(account, staff_users)
      phone_id = "109876543210987"
      existing = Channel::Whatsapp.find_by(account: account, phone_number_id: phone_id)
      inbox = if existing
        existing.primary_inbox || existing.inboxes.first
      else
        Channels::ChannelCreator.call(
          channel_type: "whatsapp",
          channel_params: {
            name: "WhatsApp Business",
            phone_code: "1",
            phone_number: "5552345678",
            full_phone_number: "+15552345678",
            phone_number_id: phone_id,
            business_account_id: "987654321098765",
            api_key: "EAAG_whatsapp_demo_token_#{SecureRandom.hex(8)}"
          },
          current_account: account
        )
        Channel::Whatsapp.find_by(account: account, phone_number_id: phone_id)&.inboxes&.first
      end

      assign_staff_to_inbox(inbox, staff_users)
      puts "    ✓ WhatsApp: #{inbox&.name}"
      inbox
    end

    def create_facebook_channel(account, staff_users)
      page_id = "102938475610293"
      existing = Channel::FacebookPage.find_by(account: account, page_identifier: page_id)
      inbox = if existing
        existing.primary_inbox || existing.inboxes.first
      else
        Channel::FacebookPage.skip_callback(:create, :after, :subscribe_to_webhooks)
        begin
          Channels::ChannelCreator.call(
            channel_type: "facebook_page",
            channel_params: {
              name: "Facebook Messenger",
              page_identifier: page_id,
              access_token: "EAAB_facebook_demo_token_#{SecureRandom.hex(8)}",
              user_access_token: "EAAB_facebook_user_demo_token_#{SecureRandom.hex(8)}"
            },
            current_account: account
          )
        ensure
          Channel::FacebookPage.set_callback(:create, :after, :subscribe_to_webhooks)
        end
        Channel::FacebookPage.find_by(account: account, page_identifier: page_id)&.inboxes&.first
      end

      assign_staff_to_inbox(inbox, staff_users)
      puts "    ✓ Facebook: #{inbox&.name}"
      inbox
    end

    def create_instagram_channel(account, staff_users)
      ig_id = "17841400012345678"
      existing = Channel::Instagram.find_by(account: account, instagram_id: ig_id)
      inbox = if existing
        existing.primary_inbox || existing.inboxes.first
      else
        Channels::ChannelCreator.call(
          channel_type: "instagram",
          channel_params: {
            name: "Instagram Direct",
            username: "deskbolic_hq",
            instagram_id: ig_id,
            access_token: "IGQV_instagram_demo_token_#{SecureRandom.hex(8)}",
            expires_at: 60.days.from_now
          },
          current_account: account
        )
        Channel::Instagram.find_by(account: account, instagram_id: ig_id)&.inboxes&.first
      end

      assign_staff_to_inbox(inbox, staff_users)
      puts "    ✓ Instagram: #{inbox&.name}"
      inbox
    end

    def create_contact_form_channel(account, staff_users)
      form_name = "Website Contact Form"
      existing = Channel::ContactForm.find_by(account: account, name: form_name)
      inbox = if existing
        existing.primary_inbox || existing.inboxes.first
      else
        Channels::ChannelCreator.call(
          channel_type: "contact_form",
          channel_params: {
            name: form_name,
            allow_attachments: true,
            send_confirmation_email: true
          },
          current_account: account
        )
        Channel::ContactForm.find_by(account: account, name: form_name)&.inboxes&.first
      end

      assign_staff_to_inbox(inbox, staff_users)
      puts "    ✓ Contact Form: #{inbox&.name}"
      inbox
    end

    def assign_staff_to_inbox(inbox, staff_users)
      return unless inbox

      staff_users.compact.uniq.each do |user|
        InboxUser.find_or_create_by!(inbox: inbox, user: user)
      end
    end

    # --- Teams ---

    def create_teams(account, agents, admin, inboxes)
      puts "  🏢 Creating teams..."

      support_team = account.teams.find_or_create_by!(name: "Support") do |t|
        t.description = "Front-line customer support & technical success"
        t.configurations = { "assignment_policy" => "round_robin" }
      end

      engineering_team = account.teams.find_or_create_by!(name: "Engineering") do |t|
        t.description = "Platform reliability & infrastructure escalations"
        t.configurations = { "assignment_policy" => "round_robin", "max_conversations_per_agent" => 10 }
      end

      sales_team = account.teams.find_or_create_by!(name: "Sales") do |t|
        t.description = "Commercial deals, onboarding & expansion"
        t.configurations = { "assignment_policy" => "round_robin" }
      end

      # Assign agents with designated leads
      [agents[0], agents[1], admin].compact.each_with_index do |user, idx|
        tu = TeamUser.find_or_create_by!(team: support_team, user: user)
        tu.update!(role: idx == 0 ? :lead : :member)
      end

      [agents[1], agents[2]].compact.each_with_index do |user, idx|
        tu = TeamUser.find_or_create_by!(team: engineering_team, user: user)
        tu.update!(role: idx == 0 ? :lead : :member)
      end

      [agents[2], agents[0], admin].compact.each_with_index do |user, idx|
        tu = TeamUser.find_or_create_by!(team: sales_team, user: user)
        tu.update!(role: idx == 0 ? :lead : :member)
      end

      # Link all teams to inboxes
      inboxes.compact.each do |inbox|
        InboxTeam.find_or_create_by!(inbox: inbox, team: support_team)
        InboxTeam.find_or_create_by!(inbox: inbox, team: engineering_team)
        InboxTeam.find_or_create_by!(inbox: inbox, team: sales_team)
      end

      puts "    ✓ Support (#{support_team.team_users.count} members, lead: #{support_team.lead&.display_name})"
      puts "    ✓ Engineering (#{engineering_team.team_users.count} members, lead: #{engineering_team.lead&.display_name})"
      puts "    ✓ Sales (#{sales_team.team_users.count} members, lead: #{sales_team.lead&.display_name})"

      [support_team, engineering_team, sales_team]
    end

    # --- Labels ---

    LABELS_DATA = [
      { title: "vip", color: "#8b5cf6", description: "High-value enterprise customer" },
      { title: "urgent", color: "#ef4444", description: "Critical issue requiring immediate attention" },
      { title: "bug", color: "#f97316", description: "Software defect or technical glitch" },
      { title: "billing", color: "#eab308", description: "Invoice, payments, or subscription query" },
      { title: "sales", color: "#ec4899", description: "Commercial lead or expansion opportunity" },
      { title: "feature-request", color: "#3b82f6", description: "Product enhancement suggestion" },
      { title: "enterprise", color: "#0284c7", description: "Enterprise tier organization" },
      { title: "onboarding", color: "#10b981", description: "New deployment or setup assistance" }
    ].freeze

    def create_labels(account)
      puts "  🏷  Creating styled labels..."

      labels_hash = {}
      LABELS_DATA.each do |data|
        label = account.labels.find_or_initialize_by(title: data[:title])
        label.color = data[:color]
        label.description = data[:description]
        label.configurations ||= {}
        label.save!
        labels_hash[data[:title]] = label
      end

      puts "    ✓ #{labels_hash.count} labels: #{LABELS_DATA.map { |l| l[:title] }.join(', ')}"
      labels_hash
    end

    # --- SLA Policy ---

    def create_sla_policy(account, inboxes)
      puts "  ⏱  Creating SLA policy..."

      policy = account.sla_policies.find_or_create_by!(name: "Enterprise SLA (15m Response)") do |sp|
        sp.description = "Guaranteed 15 minute first response and 4 hour resolution for enterprise customers."
        sp.initial_response_time_limit = 900.0 # 15 minutes
        sp.response_time_limit = 1800.0 # 30 minutes
        sp.resolution_time_limit = 14400.0 # 4 hours
        sp.during_working_hours = false
        sp.configurations = {}
      end

      inboxes.compact.each do |inbox|
        SlaInbox.find_or_create_by!(sla_policy: policy, inbox: inbox, account: account)
      end

      puts "    ✓ Policy: #{policy.name}"
      policy
    end

    # --- Customers ---

    CUSTOMERS_DATA = [
      { email: "marcus.vance@novalogistics.io", first_name: "Marcus", last_name: "Vance", full_phone_number: "+15557824190", external_id: "cust-wa-01", channel_key: :whatsapp },
      { email: "elena.rostova@cloudpeak.design", first_name: "Elena", last_name: "Rostova", external_id: "cust-fb-02", channel_key: :facebook },
      { email: "liam@apexcreative.co", first_name: "Liam", last_name: "Gallagher", external_id: "cust-ig-03", channel_key: :instagram },
      { email: "david.sterling@sterlingfin.com", first_name: "David", last_name: "Sterling", full_phone_number: "+15553928811", external_id: "cust-cf-04", channel_key: :contact_form },
      { email: "sophia.martinez@quantumretail.com", first_name: "Sophia", last_name: "Martinez", external_id: "cust-em-05", channel_key: :email },
      { email: "chloe.bennett@vertexmedia.com", first_name: "Chloe", last_name: "Bennett", external_id: "cust-wd-06", channel_key: :web_widget },
      { email: "jane.doe@example.com", first_name: "Jane", last_name: "Doe", external_id: "cust-001", channel_key: :web_widget },
      { email: "john.smith@example.com", first_name: "John", last_name: "Smith", external_id: "cust-002", channel_key: :email },
      { email: "emily.wong@example.com", first_name: "Emily", last_name: "Wong", external_id: "cust-003", channel_key: :web_widget }
    ].freeze

    def create_customers(account, inboxes)
      puts "  👤 Creating customers..."

      customers_hash = {}
      CUSTOMERS_DATA.each do |data|
        inbox = inboxes[data[:channel_key]] || inboxes[:web_widget]
        customer = Customers::CustomerCreator.call(
          account: account,
          inbox: inbox,
          external_id: data[:external_id],
          email: data[:email],
          full_phone_number: data[:full_phone_number],
          params: { first_name: data[:first_name], last_name: data[:last_name] }
        )
        customers_hash[data[:email]] = customer
        puts "    ✓ Customer: #{customer.name} (#{customer.email})"
      end

      customers_hash
    end

    # --- Sample Conversations ---

    def create_sample_conversations(account:, inboxes:, customers:, staff:, teams:, labels:, sla_policy:)
      puts "  💬 Creating showcase conversations for marketing screenshots..."

      # Clean up minimal placeholder seed conversations if present
      old_identifiers = %w[seed-conv-001 seed-conv-002 seed-conv-003]
      account.conversations.where(identifier: old_identifiers).destroy_all

      conversations_catalog = [
        # 1. WhatsApp Business - High priority, live technical issue with private note
        {
          identifier: "CNV-WA-8842",
          channel_key: :whatsapp,
          source: :whatsapp,
          title: "Webhook 429 rate limit on warehouse dispatch",
          customer: customers["marcus.vance@novalogistics.io"],
          assignee: staff[:agent1], # Sarah Miller
          team: teams[:support],
          priority: :urgent,
          status: :active,
          label_keys: %w[vip urgent enterprise],
          ai_metadata: { "sentiment" => "urgent", "category" => "Shipment Tracking & API" },
          notes: [
            { user: staff[:owner], content: "VIP account (NovaLogistics) — upgraded to Hyperbolic Tier last month. Handled promptly by Sarah." },
            { user: staff[:agent1], content: "Adjusted Redis bucket override to 5,000 rpm. Telemetry looks healthy and dispatches are clearing." }
          ],
          timeline: [
            { type: :activity, actor: staff[:agent1], event_key: "conversation.team_assigned", offset: 50 },
            { type: :activity, actor: staff[:agent1], event_key: "conversation.conversation_assigned", offset: 48 },
            { type: :message, sender: :customer, offset: 45, content: "Hey team, our automated warehouse dispatch webhook just threw a 429 rate limit error on batch #NL-8842. Can someone inspect our burst concurrency cap?" },
            { type: :activity, actor: staff[:agent1], event_key: "conversation.priority_updated", changes: { priority: %w[low urgent] }, offset: 42 },
            { type: :activity, actor: staff[:agent1], event_key: "conversation.label_added", changes: { label: [nil, "urgent"] }, offset: 41 },
            { type: :message, sender: :agent, offset: 38, content: "Hi Marcus! Looking into this right now with our infrastructure team. Let me inspect your current endpoint telemetry." },
            { type: :message, sender: :agent, offset: 34, private: true, content: "Checked NovaLogistics account — they upgraded to Hyperbolic Tier last week. Burst limit should be 5,000 req/min instead of 1,000. Adjusting Redis bucket limit now." },
            { type: :message, sender: :agent, offset: 28, content: "We've scaled your webhook concurrency limit to 5,000 requests/minute. The queued dispatches should resume draining immediately. Let me know if you see any further 429s!" },
            { type: :message, sender: :customer, offset: 20, content: "That resolved it immediately! Queue is clearing out cleanly now. Thanks for the lightning response Sarah 🙌" }
          ]
        },

        # 2. Facebook Messenger - Sales Lead / Evaluation
        {
          identifier: "CNV-FB-2041",
          channel_key: :facebook,
          source: :facebook_message,
          title: "Enterprise SSO & Okta SAML evaluation",
          customer: customers["elena.rostova@cloudpeak.design"],
          assignee: staff[:agent3], # Maria Garcia
          team: teams[:sales],
          priority: :high,
          status: :active,
          label_keys: %w[sales enterprise],
          ai_metadata: { "sentiment" => "positive", "category" => "Enterprise Sales & Migration" },
          notes: [
            { user: staff[:agent3], content: "High-intent lead: 45 support seats. Scheduled demo for tomorrow at 2 PM EST. Preparing Okta SAML environment." }
          ],
          timeline: [
            { type: :activity, actor: staff[:agent3], event_key: "conversation.team_assigned", offset: 130 },
            { type: :activity, actor: staff[:agent3], event_key: "conversation.conversation_assigned", offset: 125 },
            { type: :message, sender: :customer, offset: 120, content: "Hello! We're evaluating Deskbolic for our 45-person support organization. Does your platform support custom SSO via Okta and streaming audit logs?" },
            { type: :activity, actor: staff[:agent3], event_key: "conversation.priority_updated", changes: { priority: %w[low high] }, offset: 115 },
            { type: :activity, actor: staff[:agent3], event_key: "conversation.label_added", changes: { label: [nil, "sales"] }, offset: 110 },
            { type: :message, sender: :agent, offset: 105, content: "Hi Elena! Yes, absolutely. Deskbolic Enterprise includes SAML 2.0 / OIDC (Okta, Azure AD, Google Workspace), automated SCIM user provisioning, and streaming audit logs to Datadog or S3." },
            { type: :message, sender: :agent, offset: 100, content: "I can provision a dedicated enterprise sandbox for your team and host a 20-minute architecture overview. Would tomorrow afternoon work?" },
            { type: :message, sender: :customer, offset: 75, content: "That sounds perfect! Tomorrow at 2 PM EST works great for our team lead and myself." },
            { type: :message, sender: :agent, offset: 60, private: true, content: "High-intent enterprise lead (45 seats). Sent demo calendar link and prepared custom SAML migration guide." }
          ]
        },

        # 3. Instagram Direct - Design & Theme Customization
        {
          identifier: "CNV-IG-4491",
          channel_key: :instagram,
          source: :instagram_direct_message,
          title: "Widget theme customization & CSS properties",
          customer: customers["liam@apexcreative.co"],
          assignee: staff[:agent2], # James Chen
          team: teams[:support],
          priority: :medium,
          status: :active,
          label_keys: %w[feature-request onboarding],
          ai_metadata: { "sentiment" => "positive", "category" => "Widget Customization" },
          notes: [
            { user: staff[:agent2], content: "Customer loved the CSS variables support. Added to dark mode theme beta tester group." }
          ],
          timeline: [
            { type: :activity, actor: staff[:agent2], event_key: "conversation.team_assigned", offset: 190 },
            { type: :activity, actor: staff[:agent2], event_key: "conversation.conversation_assigned", offset: 185 },
            { type: :message, sender: :customer, offset: 180, content: "Hey! Loving the new web widget design you launched 🔥 Quick question: can we customize the launcher button border radius and brand gradients via CSS variables?" },
            { type: :activity, actor: staff[:agent2], event_key: "conversation.label_added", changes: { label: [nil, "feature-request"] }, offset: 170 },
            { type: :message, sender: :agent, offset: 160, content: "Hey Liam! Thanks so much for the love! 🙌 Yes, you can override CSS custom properties directly in your embed snippet. You can customize `--deskbolic-accent`, `--deskbolic-radius`, and `--deskbolic-header-gradient`." },
            { type: :message, sender: :customer, offset: 135, content: "Amazing, just tested `--deskbolic-radius: 16px` and it blends seamlessly with our brand theme. Thanks for the quick tip!" },
            { type: :message, sender: :agent, offset: 120, content: "Anytime! Let us know if you want early access to our dark mode theme generator next week 🎉" }
          ]
        },

        # 4. Website Contact Form - Enterprise Security & Unassigned Triage
        {
          identifier: "CNV-CF-9012",
          channel_key: :contact_form,
          source: :help_center,
          title: "SOC 2 Type II compliance & EU data residency",
          customer: customers["david.sterling@sterlingfin.com"],
          assignee: nil, # Unassigned ticket to demonstrate triage workflow!
          team: teams[:engineering],
          priority: :urgent,
          status: :active,
          label_keys: %w[enterprise urgent],
          ai_metadata: { "sentiment" => "neutral", "category" => "Security & Compliance Review" },
          notes: [
            { user: staff[:admin], content: "Received via enterprise contact form. Pending compliance NDA execution before dispatching SOC2 Type II audit report." },
            { user: staff[:owner], content: "Key financial sector account. Follow up once legal review clears." }
          ],
          timeline: [
            { type: :activity, actor: staff[:admin], event_key: "conversation.team_assigned", offset: 250 },
            { type: :activity, actor: staff[:admin], event_key: "conversation.priority_updated", changes: { priority: %w[low urgent] }, offset: 245 },
            { type: :message, sender: :customer, offset: 240, content: "Inquiry regarding SOC 2 Type II compliance report, penetration testing executive summary, and data residency guarantees for EU financial compliance." },
            { type: :activity, actor: staff[:admin], event_key: "conversation.label_added", changes: { label: [nil, "enterprise"] }, offset: 235 },
            { type: :activity, actor: staff[:admin], event_key: "conversation.label_added", changes: { label: [nil, "urgent"] }, offset: 230 },
            { type: :message, sender: :customer, offset: 220, content: "We are currently completing vendor security assessment before our annual enterprise license renewal. Please route to your compliance officer or security lead." },
            { type: :message, sender: :admin, offset: 180, private: true, content: "Received via enterprise contact form. Routing to Engineering lead for SOC2 package dispatch and standard NDA review." }
          ]
        },

        # 5. Email Support - Billing query & Snoozed state
        {
          identifier: "CNV-EM-1104",
          channel_key: :email,
          source: :email,
          title: "VAT tax ID update on annual invoice #INV-2026-089",
          customer: customers["sophia.martinez@quantumretail.com"],
          assignee: staff[:agent1], # Sarah Miller
          team: teams[:support],
          priority: :medium,
          status: :snoozed, # Snoozed state demonstration
          label_keys: %w[billing],
          ai_metadata: { "sentiment" => "neutral", "category" => "Billing & Invoicing" },
          notes: [
            { user: staff[:agent1], content: "Customer relocated HQ to Frankfurt. Snoozed pending formal tax registration document from accounting." }
          ],
          timeline: [
            { type: :activity, actor: staff[:agent1], event_key: "conversation.conversation_assigned", offset: 1440 },
            { type: :message, sender: :customer, offset: 1400, content: "Good morning, could you please update the VAT ID and billing address on our Q3 invoice (#INV-2026-089)? We recently relocated our corporate headquarters to Frankfurt." },
            { type: :activity, actor: staff[:agent1], event_key: "conversation.label_added", changes: { label: [nil, "billing"] }, offset: 1350 },
            { type: :message, sender: :agent, offset: 1300, content: "Good morning Sophia! I'd be glad to regenerate the invoice with your updated corporate details. Could you reply with your new registered address and EU VAT tax number?" },
            { type: :message, sender: :customer, offset: 1200, content: "Thank you Sarah! I've requested the formal tax certificate from our accounting department and will send it over once signed." },
            { type: :message, sender: :agent, offset: 1140, content: "Sounds great! I'll snooze this ticket until Friday while you gather the documentation. Have a wonderful week!" },
            { type: :message, sender: :agent, offset: 1130, private: true, content: "Snoozed pending VAT certificate from accounting. Ready to reissue PDF once received." },
            { type: :activity, actor: staff[:agent1], event_key: "conversation.conversation_snoozed", changes: { status: %w[active snoozed] }, offset: 1120 }
          ]
        },

        # 6. Live Chat Widget - Bug fix & Resolved state with 5-Star CSAT Rating
        {
          identifier: "CNV-WD-7719",
          channel_key: :web_widget,
          source: :web_widget,
          title: "WebSocket reconnection edge case in background tabs",
          customer: customers["chloe.bennett@vertexmedia.com"],
          assignee: staff[:agent2], # James Chen
          team: teams[:engineering],
          priority: :high,
          status: :resolved, # Resolved demonstration with CSAT
          label_keys: %w[bug],
          ai_metadata: { "sentiment" => "positive", "category" => "SDK Integration" },
          csat: {
            rating: 5,
            content: "James diagnosed and resolved our WebSocket reconnection edge case within minutes. Incredible support experience!"
          },
          notes: [
            { user: staff[:agent2], content: "Fix shipped in SDK v2.4.1. Closed ticket with 5-star customer satisfaction survey." }
          ],
          timeline: [
            { type: :activity, actor: staff[:agent2], event_key: "conversation.team_assigned", offset: 1500 },
            { type: :activity, actor: staff[:agent2], event_key: "conversation.conversation_assigned", offset: 1480 },
            { type: :message, sender: :customer, offset: 1450, content: "Hi, we noticed our custom chat frame isn't firing `onMessageReceived` when the browser tab goes into background suspension." },
            { type: :activity, actor: staff[:agent2], event_key: "conversation.priority_updated", changes: { priority: %w[low high] }, offset: 1420 },
            { type: :activity, actor: staff[:agent2], event_key: "conversation.label_added", changes: { label: [nil, "bug"] }, offset: 1410 },
            { type: :message, sender: :agent, offset: 1380, content: "Hello Chloe! That was an edge case with the Page Visibility API throttling timers in Chrome. We pushed an updated SDK bundle (v2.4.1) with background wake lock." },
            { type: :message, sender: :customer, offset: 1320, content: "Just updated to v2.4.1 in our staging environment and verified. The messages queue and process cleanly upon tab focus! Thank you so much!" },
            { type: :message, sender: :agent, offset: 1260, content: "Thrilled to hear that! Resolving this ticket for now. Feel free to ping us if you need anything else!" },
            { type: :message, sender: :customer, offset: 1200, content: "Will do, 10/10 support!" },
            { type: :activity, actor: staff[:agent2], event_key: "conversation.conversation_resolved", changes: { status: %w[active resolved] }, offset: 1190 }
          ]
        },

        # 7. Live Chat Widget - Onboarding customer
        {
          identifier: "CNV-WD-3301",
          channel_key: :web_widget,
          source: :web_widget,
          title: "Account onboarding & team mailbox configuration",
          customer: customers["jane.doe@example.com"],
          assignee: staff[:owner], # Alex Morgan
          team: teams[:support],
          priority: :low,
          status: :active,
          label_keys: %w[onboarding],
          ai_metadata: { "sentiment" => "positive", "category" => "Account Setup" },
          notes: [
            { user: staff[:owner], content: "Customer successfully set up Google Workspace auto-forwarding." }
          ],
          timeline: [
            { type: :activity, actor: staff[:owner], event_key: "conversation.team_assigned", offset: 310 },
            { type: :activity, actor: staff[:owner], event_key: "conversation.conversation_assigned", offset: 305 },
            { type: :message, sender: :customer, offset: 300, content: "Hi Alex, our team just signed up and we're configuring our shared mailboxes. Does Deskbolic support auto-forwarding from Google Workspace?" },
            { type: :activity, actor: staff[:owner], event_key: "conversation.label_added", changes: { label: [nil, "onboarding"] }, offset: 290 },
            { type: :message, sender: :owner, offset: 270, content: "Welcome aboard Jane! Yes, Google Workspace forwarding is fully supported. Under Inboxes > Email Support, copy your forwarding address and paste it into Google Workspace forwarding rules." },
            { type: :message, sender: :customer, offset: 240, content: "Got it, verified with test email and it popped right up in the dashboard. Thanks Alex!" }
          ]
        },

        # 8. Email Support - Technical feature question
        {
          identifier: "CNV-EM-5502",
          channel_key: :email,
          source: :email,
          title: "Question about custom domain SSL certificate renewal",
          customer: customers["john.smith@example.com"],
          assignee: staff[:admin], # Jordan Blake
          team: teams[:engineering],
          priority: :medium,
          status: :active,
          label_keys: %w[feature-request],
          ai_metadata: { "sentiment" => "neutral", "category" => "Custom Domains" },
          notes: [
            { user: staff[:admin], content: "Explained automatic Cloudflare edge SSL issuance." }
          ],
          timeline: [
            { type: :activity, actor: staff[:admin], event_key: "conversation.team_assigned", offset: 370 },
            { type: :activity, actor: staff[:admin], event_key: "conversation.conversation_assigned", offset: 365 },
            { type: :message, sender: :customer, offset: 360, content: "Hi team, does the Help Center custom domain feature handle automatic Let's Encrypt SSL certificate provisioning and renewal?" },
            { type: :activity, actor: staff[:admin], event_key: "conversation.label_added", changes: { label: [nil, "feature-request"] }, offset: 340 },
            { type: :message, sender: :admin, offset: 330, content: "Hello John! Yes, once you add your CNAME record pointing to our edge proxy, Deskbolic automatically provisions and auto-renews TLS certificates via Cloudflare edge." },
            { type: :message, sender: :customer, offset: 300, content: "Perfect, that saves our DevOps team a ton of work. Appreciate the clarification!" }
          ]
        }
      ]

      base_time = Time.current

      conversations_catalog.each do |catalog_entry|
        inbox = inboxes[catalog_entry[:channel_key]]
        next unless inbox

        conversation = account.conversations.find_or_initialize_by(identifier: catalog_entry[:identifier])
        conversation.assign_attributes(
          inbox: inbox,
          source: catalog_entry[:source],
          title: catalog_entry[:title],
          priority: catalog_entry[:priority],
          status: catalog_entry[:status],
          team: catalog_entry[:team],
          assignee: catalog_entry[:assignee],
          ai_metadata: catalog_entry[:ai_metadata] || {},
          data: {},
          configurations: {}
        )
        conversation.save!

        # Link customer participant
        if catalog_entry[:customer]
          conversation.conversation_members.find_or_create_by!(
            member: catalog_entry[:customer],
            account: account
          ) { |cm| cm.role = :participant }
        end

        # Link assignee participant
        if catalog_entry[:assignee]
          conversation.conversation_members.find_or_create_by!(
            member: catalog_entry[:assignee],
            account: account
          ) { |cm| cm.role = :participant }
        end

        # Apply labels
        Array(catalog_entry[:label_keys]).each do |label_key|
          label = labels[label_key]
          next unless label

          AppliedLabel.find_or_create_by!(label: label, labelable: conversation)
        end

        # Attach SLA
        if sla_policy
          sla_record = ConversationSla.find_or_initialize_by(
            account: account,
            conversation: conversation,
            sla_policy: sla_policy
          )
          sla_record.status = catalog_entry[:status] == :resolved ? :successful : :pending
          sla_record.target_first_response_at = conversation.created_at + 15.minutes
          sla_record.target_resolution_at = conversation.created_at + 4.hours
          sla_record.save!
        end

        # Attach internal notes for inspector panel (visible to owner, admin, and assignee)
        Array(catalog_entry[:notes]).each do |note_data|
          note_users = [note_data[:user], staff[:owner], staff[:admin], catalog_entry[:assignee]].compact.uniq
          note_users.each do |user|
            Note.find_or_create_by!(
              account: account,
              resource: conversation,
              user: user
            ) do |n|
              n.content = note_data[:content]
              n.visibility = :personal
            end
          end
        end

        # Build message & activity timeline
        conversation.messages.destroy_all
        conversation.activities.destroy_all

        sorted_timeline = catalog_entry[:timeline].sort_by { |item| -item[:offset] }
        first_item_time = base_time - (sorted_timeline.first[:offset] || 60).minutes
        last_item_time  = base_time - (sorted_timeline.last[:offset] || 10).minutes

        sorted_timeline.each do |item|
          item_time = base_time - item[:offset].minutes

          if item[:type] == :message
            sender = item[:sender] == :customer ? catalog_entry[:customer] : (staff[item[:sender]] || catalog_entry[:assignee] || staff[:agent1])
            is_private = item[:private] == true

            conversation.messages.create!(
              account: account,
              inbox: inbox,
              sender: sender,
              content: item[:content],
              source: catalog_entry[:source],
              visibility: is_private ? :personal : :global,
              status: :delivered,
              created_at: item_time,
              data: {}
            )
          elsif item[:type] == :activity
            actor = item[:actor] || catalog_entry[:assignee] || staff[:admin]

            Activity.create!(
              account: account,
              trackable: conversation,
              actor: actor,
              event_key: item[:event_key],
              object_changes: item[:changes] || {},
              created_at: item_time
            )
          end
        end

        # Handle CSAT on resolved conversation
        if catalog_entry[:csat] && catalog_entry[:status] == :resolved
          csat_time = last_item_time + 1.minute
          csat_msg = conversation.messages.create!(
            account: account,
            inbox: inbox,
            sender: catalog_entry[:assignee] || staff[:agent2],
            content_type: :csat,
            content: "Customer satisfaction survey",
            source: catalog_entry[:source],
            visibility: :global,
            status: :delivered,
            created_at: csat_time,
            data: {}
          )

          Csat::SurveyResponse.find_or_create_by!(
            account: account,
            conversation: conversation,
            customer: catalog_entry[:customer]
          ) do |csr|
            csr.message = csat_msg
            csr.rating = catalog_entry[:csat][:rating]
            csr.content = catalog_entry[:csat][:content]
            csr.status = :submitted
          end

          last_item_time = csat_time
        end

        # Touch created_at, last_activity_at, and status timestamps
        conversation.update_columns(
          created_at: first_item_time,
          last_activity_at: last_item_time,
          status_changed_at: last_item_time,
          updated_at: last_item_time
        )
      end

      puts "    ✓ #{conversations_catalog.count} rich multi-channel conversations created!"
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
      full_name = "#{first_name} #{last_name}".strip
      user = User.find_by(email: email)
      if user
        user.update_columns(name: full_name, display_name: full_name) if user.display_name.blank? || user.name.blank?
        return user
      end

      User.create!(
        email: email,
        password: "password123",
        first_name: first_name,
        last_name: last_name,
        name: full_name,
        display_name: full_name,
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

    def print_summary(account, owner, admin, agents, teams, inboxes, labels, customers)
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
      puts "  🏢 Teams:   #{teams.map(&:name).join(', ')}"
      puts "  📬 Inboxes: #{inboxes.compact.map(&:name).join(', ')}"
      puts "  🏷  Labels:  #{labels.map(&:title).join(', ')}"
      puts "  👥 Customers: #{customers.count}"
      puts ""
      puts "=" * 60
      puts ""
    end
  end
end

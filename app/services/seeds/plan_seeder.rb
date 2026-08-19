# frozen_string_literal: true

module Seeds
  class PlanSeeder
    # Base configuration templates for the 4 plans
    BASE_PLANS = {
      Plan::SYMBOLIC => {
        position: 0,
        trial_days: 0,
        limits: {
          "users_min" => 1,
          "users_max" => 2,
          "channels" => 1,
          "ai_agents" => 0,
          "automations" => 0,
          "macros" => 0,
          "sla_policies" => 0,
          "csat_surveys" => 0,
          "email_templates" => 0,
          "email_template_layouts" => 0,
          "help_center_portals" => 0,
          "custom_domains" => 0,
          "business_hour_groups" => 0,
          "teams" => 0,
          "custom_roles" => 0,
          "assignment_policies" => 0,
          "identity_sources" => 0,
          "custom_fields" => 0,
          "customers" => 500,
          "conversations_monthly" => 100,
          "messages_monthly" => 500,
          "data_retention_months" => 3
        },
        features: {
          "monthly_ai_credits" => 0,
          "sla" => false,
          "api_access" => false,
          "ai_copilot" => false,
          "ai_agent" => false,
          "csat" => false,
          "email_templates" => false,
          "custom_csat" => false,
          "custom_fields" => false,
          "automations" => false,
          "macros" => false,
          "audit_logs" => false,
          "labels" => false,
          "teams" => false,
          "roles" => true,
          "custom_roles" => false,
          "assignment_policies" => false,
          "identity_sources" => false,
          "custom_domains" => false,
          "business_hours" => false,
          "help_center_portals" => false,
          "custom_branding" => false,
          "channels" => {
            "web_widget" => true,
            "email" => false,
            "custom" => false,
            "contact_form" => false,
            "twitter" => false,
            "facebook" => false,
            "whatsapp" => false,
            "sms" => false,
            "line" => false,
            "telegram" => false,
            "instagram" => false
          }
        }
      },
      Plan::ANABOLIC => {
        position: 1,
        trial_days: 14,
        limits: {
          "users_min" => 2,
          "users_max" => 10,
          "channels" => 5,
          "ai_agents" => 0,
          "automations" => 5,
          "macros" => 20,
          "sla_policies" => 0,
          "csat_surveys" => 1,
          "email_templates" => 5,
          "email_template_layouts" => 2,
          "help_center_portals" => 1,
          "custom_domains" => 0,
          "business_hour_groups" => 0,
          "teams" => 3,
          "custom_roles" => 0,
          "assignment_policies" => 0,
          "identity_sources" => 0,
          "custom_fields" => 0,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 12
        },
        features: {
          "monthly_ai_credits" => 100,
          "sla" => false,
          "api_access" => false,
          "ai_copilot" => true,
          "ai_agent" => false,
          "csat" => true,
          "email_templates" => true,
          "custom_csat" => false,
          "custom_fields" => false,
          "automations" => true,
          "macros" => true,
          "audit_logs" => false,
          "labels" => true,
          "teams" => true,
          "roles" => true,
          "custom_roles" => false,
          "assignment_policies" => false,
          "identity_sources" => false,
          "custom_domains" => false,
          "business_hours" => false,
          "help_center_portals" => true,
          "custom_branding" => false,
          "channels" => {
            "web_widget" => true,
            "email" => true,
            "custom" => false,
            "contact_form" => true,
            "twitter" => true,
            "facebook" => true,
            "whatsapp" => true,
            "sms" => true,
            "line" => true,
            "telegram" => true,
            "instagram" => true
          }
        }
      },
      Plan::HYPERBOLIC => {
        position: 2,
        trial_days: 14,
        limits: {
          "users_min" => 4,
          "users_max" => 30,
          "channels" => 15,
          "ai_agents" => 3,
          "automations" => 25,
          "macros" => 100,
          "sla_policies" => 5,
          "csat_surveys" => 5,
          "email_templates" => 25,
          "email_template_layouts" => 10,
          "help_center_portals" => 3,
          "custom_domains" => 3,
          "business_hour_groups" => 3,
          "teams" => 10,
          "custom_roles" => 5,
          "assignment_policies" => 5,
          "identity_sources" => 0,
          "custom_fields" => 20,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 36
        },
        features: {
          "monthly_ai_credits" => 250,
          "sla" => true,
          "api_access" => true,
          "ai_copilot" => true,
          "ai_agent" => true,
          "csat" => true,
          "email_templates" => true,
          "custom_csat" => true,
          "custom_fields" => true,
          "automations" => true,
          "macros" => true,
          "audit_logs" => true,
          "labels" => true,
          "teams" => true,
          "roles" => true,
          "custom_roles" => true,
          "assignment_policies" => true,
          "identity_sources" => false,
          "custom_domains" => true,
          "business_hours" => true,
          "help_center_portals" => true,
          "custom_branding" => false,
          "channels" => {
            "web_widget" => true,
            "email" => true,
            "custom" => false,
            "contact_form" => true,
            "twitter" => true,
            "facebook" => true,
            "whatsapp" => true,
            "sms" => true,
            "line" => true,
            "telegram" => true,
            "instagram" => true
          }
        }
      },
      Plan::PARABOLIC => {
        position: 3,
        trial_days: 14,
        limits: {
          "users_min" => 10,
          "users_max" => -1,
          "channels" => 50,
          "ai_agents" => 15,
          "automations" => 100,
          "macros" => 500,
          "sla_policies" => 25,
          "csat_surveys" => 25,
          "email_templates" => 100,
          "email_template_layouts" => 25,
          "help_center_portals" => 10,
          "custom_domains" => 10,
          "business_hour_groups" => 10,
          "teams" => 50,
          "custom_roles" => 25,
          "assignment_policies" => 25,
          "identity_sources" => 10,
          "custom_fields" => 100,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 60
        },
        features: {
          "monthly_ai_credits" => 500,
          "sla" => true,
          "api_access" => true,
          "ai_copilot" => true,
          "ai_agent" => true,
          "csat" => true,
          "email_templates" => true,
          "custom_csat" => true,
          "custom_fields" => true,
          "automations" => true,
          "macros" => true,
          "audit_logs" => true,
          "labels" => true,
          "teams" => true,
          "roles" => true,
          "custom_roles" => true,
          "custom_branding" => true,
          "assignment_policies" => true,
          "identity_sources" => true,
          "custom_domains" => true,
          "business_hours" => true,
          "help_center_portals" => true,
          "channels" => {
            "web_widget" => true,
            "email" => true,
            "custom" => true,
            "contact_form" => true,
            "twitter" => true,
            "facebook" => true,
            "whatsapp" => true,
            "sms" => true,
            "line" => true,
            "telegram" => true,
            "instagram" => true
          }
        }
      }
    }.freeze

    # Hyper-Competitive Pricing Strategy mapping (base, annual)
    PRICING = {
      "USD" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [9, 8],
        Plan::HYPERBOLIC => [19, 17],
        Plan::PARABOLIC => [49, 44]
      },
      "EUR" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [9, 8], # Competitive parity
        Plan::HYPERBOLIC => [19, 17], # Competitive parity
        Plan::PARABOLIC => [49, 44] # Competitive parity
      },
      "GBP" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [8, 7], # Proportionally lower
        Plan::HYPERBOLIC => [15, 13],
        Plan::PARABOLIC => [39, 35]
      },
      "KRW" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [12000, 11000],
        Plan::HYPERBOLIC => [26000, 23000],
        Plan::PARABOLIC => [66000, 59000]
      }
    }.freeze

    def self.seed
      Core::SUPPORTED_CURRENCIES.each do |currency|
        Plan::NAMES.each do |name|
          plan_data = BASE_PLANS[name].dup
          pricing = PRICING[currency][name]
          
          plan = Plan.find_or_initialize_by(name: name, currency: currency)
          plan.assign_attributes(plan_data)
          plan.base_price = pricing[0]
          plan.annual_price = pricing[1]
          plan.save!

          # Create default English translation
          unless plan.translated_to?(:en)
            plan.translations.create!(
              locale: "en",
              display_name: I18n.t("billing.plans.#{name}.display_name", locale: :en, default: name.capitalize),
              description: I18n.t("billing.plans.#{name}.description", locale: :en, default: "#{name.capitalize} plan")
            )
          end
        end
      end
    end
  end
end

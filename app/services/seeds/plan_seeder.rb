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
          "customers" => 500,
          "conversations_monthly" => 100,
          "messages_monthly" => 500,
          "data_retention_months" => 3
        },
        configurations: {
          "sla" => false,
          "api_access" => false,
          "csat" => false,
          "email_templates" => false,
          "audit_logs" => false,
          "teams" => false,
          "assignment_policies" => false,
          "channels" => {
            "web_widget" => true,
            "email" => false,
            "api" => false,
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
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 12
        },
        configurations: {
          "sla" => true,
          "api_access" => true,
          "csat" => false,
          "email_templates" => false,
          "audit_logs" => false,
          "teams" => true,
          "assignment_policies" => false,
          "channels" => {
            "web_widget" => true,
            "email" => true,
            "api" => true,
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
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 24
        },
        configurations: {
          "sla" => true,
          "api_access" => true,
          "csat" => true,
          "email_templates" => true,
          "audit_logs" => true,
          "teams" => true,
          "assignment_policies" => true,
          "channels" => {
            "web_widget" => true,
            "email" => true,
            "api" => true,
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
          "channels" => -1,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 36
        },
        configurations: {
          "sla" => true,
          "api_access" => true,
          "csat" => true,
          "email_templates" => true,
          "audit_logs" => true,
          "teams" => true,
          "custom_branding" => true,
          "assignment_policies" => true,
          "channels" => {
            "web_widget" => true,
            "email" => true,
            "api" => true,
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
        Plan::ANABOLIC => [10, 8],
        Plan::HYPERBOLIC => [19, 15],
        Plan::PARABOLIC => [49, 39]
      },
      "EUR" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [10, 8], # Competitive parity
        Plan::HYPERBOLIC => [19, 15], # Competitive parity
        Plan::PARABOLIC => [49, 39] # Competitive parity
      },
      "GBP" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [8, 6], # Proportionally lower
        Plan::HYPERBOLIC => [15, 12],
        Plan::PARABOLIC => [39, 31]
      },
      "KRW" => {
        Plan::SYMBOLIC => [0, 0],
        Plan::ANABOLIC => [14000, 11000],
        Plan::HYPERBOLIC => [26000, 21000],
        Plan::PARABOLIC => [68000, 54000]
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

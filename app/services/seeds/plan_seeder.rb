# frozen_string_literal: true

module Seeds
  class PlanSeeder
    PLANS = [
      {
        name: Plan::STARTER,
        base_price: 0,
        annual_price: 0,
        trial_days: 0,
        position: 0,
        contact_us: false,
        limits: {
          "users" => 2,
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
          "teams" => false
        }
      },
      {
        name: Plan::MOMENTUM,
        base_price: 10,
        annual_price: 8,
        trial_days: 14,
        position: 1,
        contact_us: false,
        limits: {
          "users" => 10,
          "channels" => 5,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 6
        },
        configurations: {
          "sla" => false,
          "api_access" => false,
          "csat" => false,
          "email_templates" => true,
          "audit_logs" => true,
          "teams" => true
        }
      },
      {
        name: Plan::PINNACLE,
        base_price: 39,
        annual_price: 31,
        trial_days: 14,
        position: 2,
        contact_us: false,
        limits: {
          "users" => 30,
          "channels" => 15,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => 12
        },
        configurations: {
          "sla" => true,
          "api_access" => true,
          "csat" => true,
          "email_templates" => true,
          "audit_logs" => true,
          "teams" => true
        }
      },
      {
        name: Plan::ENTERPRISE,
        base_price: 0,
        annual_price: 0,
        trial_days: 0,
        position: 3,
        contact_us: true,
        limits: {
          "users" => -1,
          "channels" => -1,
          "conversations_monthly" => -1,
          "messages_monthly" => -1,
          "customers" => -1,
          "data_retention_months" => -1
        },
        configurations: {
          "sla" => true,
          "api_access" => true,
          "csat" => true,
          "email_templates" => true,
          "audit_logs" => true,
          "teams" => true,
          "dedicated_support" => true,
          "custom_branding" => true
        }
      }
    ].freeze

    def self.seed
      PLANS.each do |plan_data|
        plan = Plan.find_or_initialize_by(name: plan_data[:name])
        plan.assign_attributes(plan_data.except(:name))
        plan.save!

        # Create default English translation
        unless plan.translated_to?(:en)
          plan.translations.create!(
            locale: "en",
            display_name: I18n.t("billing.plans.#{plan_data[:name]}.display_name", locale: :en),
            description: I18n.t("billing.plans.#{plan_data[:name]}.description", locale: :en)
          )
        end
      end
    end
  end
end

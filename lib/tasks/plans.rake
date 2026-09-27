# frozen_string_literal: true

namespace :plans do
  desc "Update existing plans in production (synchronizes pricing, limits, features, and translations from PlanSeeder)"
  task update: :environment do
    puts "=========================================================="
    puts " Synchronizing and Updating Plans from PlanSeeder"
    puts "=========================================================="

    created_count = 0
    updated_count = 0
    unchanged_count = 0

    Core::SUPPORTED_CURRENCIES.each do |currency|
      Plan::NAMES.each do |name|
        plan_data = Seeds::PlanSeeder::BASE_PLANS[name].dup
        pricing = Seeds::PlanSeeder::PRICING[currency][name]

        plan = Plan.find_or_initialize_by(name: name, currency: currency)
        is_new = plan.new_record?

        plan.assign_attributes(plan_data)
        plan.base_price = pricing[0]
        plan.annual_price = pricing[1]

        if is_new
          plan.save!
          created_count += 1
          puts " [CREATED] Plan: #{name.upcase} (#{currency}) - Monthly: #{pricing[0]}, Annual: #{pricing[1]}"
        elsif plan.changed?
          changes = plan.changes
          plan.save!
          updated_count += 1
          puts " [UPDATED] Plan: #{name.upcase} (#{currency}) - Changes: #{changes.keys.join(', ')} (Monthly: #{pricing[0]}, Annual: #{pricing[1]})"
        else
          unchanged_count += 1
          puts " [UNCHANGED] Plan: #{name.upcase} (#{currency}) - Monthly: #{pricing[0]}, Annual: #{pricing[1]}"
        end

        # Ensure default English translation exists
        unless plan.translated_to?(:en)
          plan.translations.create!(
            locale: "en",
            display_name: I18n.t("billing.plans.#{name}.display_name", locale: :en, default: name.capitalize),
            description: I18n.t("billing.plans.#{name}.description", locale: :en, default: "#{name.capitalize} plan")
          )
        end
      end
    end

    puts "=========================================================="
    puts " Synchronization complete: #{created_count} created, #{updated_count} updated, #{unchanged_count} unchanged (Total: #{Plan.count})"
    puts "=========================================================="
  end
end

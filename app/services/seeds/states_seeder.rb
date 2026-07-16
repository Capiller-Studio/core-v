# frozen_string_literal: true


EXCLUDED_US_STATES = %w[UM AS MP VI PR GU].freeze
EXCLUDED_CN_STATES = %w[HK MO TW].freeze

module Seeds
  class StatesSeeder
    def seed
      puts "Seeding states ⏳️"
      Country.all.each do |country|
        carmen_country = Carmen::Country.coded(country.iso)
        next unless carmen_country

        seed_country(country, carmen_country)
      end
      puts "Total states: #{State.count} ⚡️"
    end

    def seed_country(country, carmen_country)
      carmen_country.subregions.each do |subregion|
        seed_subregion(subregion, country, carmen_country)
      end
    end

    def seed_subregion(subregion, country, carmen_country)
      return if exluded_subregion?(carmen_country, subregion)

      if subregion.subregions?
        seed_province(country, subregion)
      else
        seed_state(country, subregion)
      end
    end

    def exluded_subregion?(carmen_country, subregion)
      (carmen_country.alpha_2_code == "US" && EXCLUDED_US_STATES.include?(subregion.code)) ||
        (carmen_country.alpha_2_code == "CA" || carmen_country.alpha_2_code == "MX") ||
        (carmen_country.alpha_2_code == "CN" && EXCLUDED_CN_STATES.include?(subregion.code))
    end

    def seed_state(country, subregion)
      country.states.where(abbr: subregion.code).first_or_create!
    end

    def seed_province(country, subregion)
      subregion.subregions.each do |province|
        country.states.where(abbr: subregion.code).first_or_create!
      end
    end
  end
end

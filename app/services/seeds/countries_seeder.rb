# frozen_string_literal: true


EXCLUDED_COUNTRIES = %w[AQ AX GS UM HM IO EH BV TF].freeze

module Seeds
  class CountriesSeeder
    def seed
      puts "Seeding countries ⏳️"
      Carmen::Country.all.each do |country|
        # Skip the creation of some territories, uninhabited islands and the Antarctic.
        next if EXCLUDED_COUNTRIES.include?(country.alpha_2_code)

        c = Country.find_or_initialize_by(iso: country.alpha_2_code)
        c.update!(
          iso3: country.alpha_3_code,
          iso_name: country.name.upcase,
          numeric_code: country.numeric_code
        )
      end

      # rubocop:disable Rails/SkipsModelValidations
      Country.where(iso: %w[US CA AU]).update_all(states_required: true)
      # rubocop:enable Rails/SkipsModelValidations
      puts "Total countries: #{Country.count} ⚡️"
    end
  end
end

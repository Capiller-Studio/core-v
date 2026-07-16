require 'rails_helper'

RSpec.xdescribe Seeds::CountriesSeeder do
  describe '#seed' do
    it 'creates countries and updates required states for specific countries' do
      # Note: This test requires 'carmen' gem which is used in the seeder.
      # Because the list of countries is huge, we will mock Carmen::Country.all
      # to return a small subset for fast testing.
      us_country = double('Carmen::Country', alpha_2_code: 'US', alpha_3_code: 'USA', name: 'United States', numeric_code: '840')
      ca_country = double('Carmen::Country', alpha_2_code: 'CA', alpha_3_code: 'CAN', name: 'Canada', numeric_code: '124')
      excluded_country = double('Carmen::Country', alpha_2_code: 'AQ', alpha_3_code: 'ATA', name: 'Antarctica', numeric_code: '010')

      allow(Carmen::Country).to receive(:all).and_return([us_country, ca_country, excluded_country])

      expect {
        described_class.new.seed
      }.to change { Country.count }.by(2)

      expect(Country.find_by(iso: 'US')).to have_attributes(
        iso3: 'USA',
        iso_name: 'UNITED STATES',
        numeric_code: 840,
        states_required: true
      )

      expect(Country.find_by(iso: 'CA')).to have_attributes(
        states_required: true
      )

      expect(Country.find_by(iso: 'AQ')).to be_nil
    end

    it 'is idempotent' do
      us_country = double('Carmen::Country', alpha_2_code: 'US', alpha_3_code: 'USA', name: 'United States', numeric_code: '840')
      allow(Carmen::Country).to receive(:all).and_return([us_country])

      described_class.new.seed

      expect {
        described_class.new.seed
      }.not_to change { Country.count }
    end
  end
end

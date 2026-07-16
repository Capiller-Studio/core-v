require 'rails_helper'

RSpec.xdescribe Seeds::StatesSeeder do
  let!(:us_country) { create(:country, iso: 'US') }
  let!(:ca_country) { create(:country, iso: 'CA') }

  describe '#seed' do
    it 'creates states for countries using carmen data' do
      expect {
        described_class.new.seed
      }.to change { State.count }.by_at_least(50) # US has 50+ states

      expect(us_country.states.pluck(:abbr)).to include('CA', 'NY')
      expect(us_country.states.pluck(:abbr)).not_to include('PR') # PR is excluded
      
      # Canada is excluded entirely in the seeder
      expect(ca_country.states.count).to eq(0)
    end

    it 'is idempotent' do
      described_class.new.seed

      expect {
        described_class.new.seed
      }.not_to change { State.count }
    end
  end
end

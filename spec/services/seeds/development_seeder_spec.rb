require 'rails_helper'

RSpec.describe Seeds::DevelopmentSeeder do
  describe '#seed' do
    it 'runs without errors and creates development data' do
      # Because DevelopmentSeeder uses Searchkick heavily via HelpCenterSeeder,
      # we need to disable callbacks to avoid ElasticSearch connection errors
      # and we should mock external services if they hit the network.
      
      Searchkick.callbacks(false) do
        allow_any_instance_of(described_class).to receive(:assign_billing_defaults!)

        # Expect the seeder to run without raising exceptions
        expect {
          described_class.seed
        }.not_to raise_error
        
        # Verify that it created the expected records
        account = Account.find_by(name: 'Deskbolic Demo')
        expect(account).not_to be_nil
        
        owner = User.find_by(email: 'owner@deskbolic.test')
        expect(owner).not_to be_nil
        
        admin = User.find_by(email: 'admin@deskbolic.test')
        expect(admin).not_to be_nil
        
        expect(account.teams.count).to be >= 2
        expect(account.inboxes.count).to be >= 1
        expect(account.conversations.count).to be >= 3
      end
    end
  end
end

require 'rails_helper'

RSpec.xdescribe Seeds::HelpCenterSeeder do
  let(:account) { create(:account) }

  describe '#seed' do
    it 'creates a portal, contact form, categories, and articles' do
      Searchkick.callbacks(false) do
        expect {
          described_class.new(account: account).seed
        }.to change { Domain.count }.by(1)
         .and change { HelpCenter::Portal.count }.by(1)
         .and change { Channel::ContactForm.count }.by(1)
      end

      account.with_shard do
        portal = HelpCenter::Portal.find_by(account: account)
        expect(portal.name).to eq('Techbolic Support Center')
        
        # Verify categories were created
        expect(portal.categories.count).to be >= 6

        # Verify articles were created
        expect(portal.articles.count).to be >= 10
      end
    end

    it 'is idempotent' do
      Searchkick.callbacks(false) do
        described_class.new(account: account).seed

        expect {
          described_class.new(account: account).seed
        }.to change { Domain.count }.by(0)
         .and change { HelpCenter::Portal.count }.by(0)
         .and change { Channel::ContactForm.count }.by(0)
      end
    end
  end
end

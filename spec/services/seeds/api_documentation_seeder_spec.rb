require 'rails_helper'

RSpec.describe Seeds::ApiDocumentationSeeder do
  describe '.seed' do
    let(:domain) { 'api-docs.example.com' }

    context 'when no account exists' do
      it 'does nothing and skips seeding' do
        allow(Account).to receive(:first).and_return(nil)
        Searchkick.callbacks(false) do
          expect { described_class.seed(domain: domain) }.not_to change { Domain.count }
          expect { described_class.seed(domain: domain) }.not_to change { HelpCenter::Portal.count }
        end
      end
    end

    context 'when an account exists' do
      let!(:account) { create(:account) }

      it 'creates a domain, help center portal, categories, and articles' do
        Searchkick.callbacks(false) do
          expect {
            described_class.seed(domain: domain)
          }.to change { Domain.count }.by(1)
           .and change { HelpCenter::Portal.count }.by(1)
           .and change { HelpCenter::Category.count }.by(5)
           .and change { HelpCenter::Article.count }.by(8)
        end

        account.with_shard do
          domain_record = Domain.find_by(value: domain)
          expect(domain_record).not_to be_nil
          expect(domain_record.value).to eq(domain)
          expect(domain_record.status).to eq('active')
          expect(domain_record.dns_status).to eq('dns_verified')

          portal = HelpCenter::Portal.find_by(domain_id: domain_record.id)
          expect(portal).not_to be_nil
          expect(portal.name).to eq('Deskbolic API Reference')
          expect(portal.default_locale).to eq('en')
          expect(portal.locales).to match_array(['en', 'fr', 'es'])
          expect(portal.domain_id).to eq(domain_record.id)

          expect(portal.categories.count).to eq(5)
          expect(portal.articles.count).to eq(8)
        end
      end

      it 'is idempotent' do
        Searchkick.callbacks(false) do
          described_class.seed(domain: domain)

          expect {
            described_class.seed(domain: domain)
          }.to change { Domain.count }.by(0)
           .and change { HelpCenter::Portal.count }.by(0)
           .and change { HelpCenter::Category.count }.by(0)
           .and change { HelpCenter::Article.count }.by(0)
        end
      end
    end
  end
end

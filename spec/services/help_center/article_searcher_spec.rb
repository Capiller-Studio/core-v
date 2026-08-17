require 'rails_helper'

RSpec.describe HelpCenter::ArticleSearcher, search: true do
  let(:account) { create(:account) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:other_portal) { create(:help_center_portal, account: account) }

  before(:all) do
    Searchkick.disable_callbacks
  end

  after(:all) do
    Searchkick.enable_callbacks
  end

  before do
    allow(HelpCenter::Article).to receive(:search).and_return([])
  end

  let!(:article1) do
    create(:help_center_article,
           account: account,
           portal: portal,
           title: 'How to reset your password',
           content: 'Follow these steps to reset your password securely.',
           status: :published,
           views_count: 100)
  end

  let!(:article2) do
    create(:help_center_article,
           account: account,
           portal: portal,
           title: 'Billing FAQ',
           content: 'Questions about invoices and billing.',
           status: :published,
           views_count: 5)
  end

  let!(:draft_article) do
    create(:help_center_article,
           account: account,
           portal: portal,
           title: 'Secret Upcoming Feature',
           content: 'This feature is not released yet.',
           status: :draft)
  end

  let!(:other_portal_article) do
    create(:help_center_article,
           account: account,
           portal: other_portal,
           title: 'Password policy for other portal',
           content: 'Different rules apply here.',
           status: :published)
  end



  describe '#call' do
    it 'returns empty array if query is blank' do
      service = described_class.new(query: '', account: account, portal: portal)
      expect(service.call).to eq([])
    end

    it 'returns empty array if portal is blank' do
      service = described_class.new(query: 'password', account: account, portal: nil)
      expect(service.call).to eq([])
    end

    it 'returns matching published articles for the given portal' do
      expect(HelpCenter::Article).to receive(:search).with(
        'password',
        hash_including(where: { account_id: account.id, portal_id: portal.id, status: "published" })
      ).and_return([article1])

      service = described_class.new(query: 'password', account: account, portal: portal, locale: 'en')
      results = service.call

      expect(results).to eq([article1])
    end

    it 'searches within the content as well' do
      expect(HelpCenter::Article).to receive(:search).with(
        'invoices',
        hash_including(match: :word_start, fields: ["translations.title^3", "translations.content"])
      ).and_return([article2])

      service = described_class.new(query: 'invoices', account: account, portal: portal, locale: 'en')
      results = service.call

      expect(results).to eq([article2])
    end

    it 'boosts articles with higher view counts' do
      expect(HelpCenter::Article).to receive(:search).with(
        'billing',
        hash_including(boost_by: { views_count: { factor: 1.2 } })
      ).and_return([article1, article2])

      service = described_class.new(query: 'billing', account: account, portal: portal, locale: 'en')
      results = service.call
      
      expect(results.map(&:id)).to eq([article1.id, article2.id])
    end
  end
end

require 'rails_helper'

RSpec.describe HelpCenter::ArticleSearcher do
  let(:account) { double('Account', id: 1) }
  let(:portal) { double('Portal', id: 2) }

  describe '#call' do
    before do
      stub_const('HelpCenter::Article', double('ArticleClass'))
      allow(HelpCenter::Article).to receive(:search).and_return([])
    end

    it 'returns empty array if query is blank' do
      service = described_class.new(query: '', account: account, portal: portal)
      expect(service.call).to eq([])
    end

    it 'returns empty array if portal is blank' do
      service = described_class.new(query: 'test', account: account, portal: nil)
      expect(service.call).to eq([])
    end

    it 'calls Article.search with correct parameters' do
      service = described_class.new(query: 'test query', account: account, portal: portal, locale: 'en')
      
      expect(HelpCenter::Article).to receive(:search).with(
        'test query',
        where: {
          account_id: 1,
          portal_id: 2,
          status: 'published'
        },
        fields: ["translations.title^3", "translations.content"],
        match: :word_start,
        boost_by: { views_count: { factor: 1.2 } }
      ).and_return(['article1'])

      expect(service.call).to eq(['article1'])
    end
  end
end

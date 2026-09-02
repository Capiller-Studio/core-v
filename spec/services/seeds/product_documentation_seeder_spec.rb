# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seeds::ProductDocumentationSeeder do
  let(:account) { create(:account) }
  let(:domain_name) { "docs-test-#{SecureRandom.hex(4)}.deskbolic.localhost" }
  let(:api_domain_name) { "api-test-#{SecureRandom.hex(4)}.deskbolic.localhost" }

  describe ".seed" do
    it "creates User Guide portal, 10 feature categories, articles with API cross-link, and all 7 locale translations" do
      expect {
        described_class.seed(account: account, domain: domain_name, api_portal_domain: api_domain_name)
      }.not_to raise_error

      account.with_shard do
        domain_record = Domain.find_by(value: domain_name)
        expect(domain_record).to be_present

        portal = HelpCenter::Portal.find_by(domain_id: domain_record.id)
        expect(portal).to be_present
        expect(portal.name).to eq("Deskbolic User Guide & Help Center")
        expect(portal.locales).to match_array(Core::SUPPORTED_LOCALES.map(&:to_s))
        expect(portal.translations.count).to eq(7)

        expect(portal.categories.count).to eq(11)

        # Verify Knowledge Base category and cross-link article
        kb_cat = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: "en", name: "Knowledge Base & Help Center" })
        expect(kb_cat).to be_present
        expect(kb_cat.translations.count).to eq(7)

        api_link_art = kb_cat.articles.joins(:translations).find_by(help_center_article_translations: { locale: "en", title: "Developer Platform & API Reference Portal" })
        expect(api_link_art).to be_present
        expect(api_link_art.translations.find_by(locale: "en").content).to include(api_domain_name)
        expect(api_link_art.translations.count).to eq(7)
      end
    end
  end
end

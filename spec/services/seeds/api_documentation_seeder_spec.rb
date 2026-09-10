# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seeds::ApiDocumentationSeeder do
  let(:account) { create(:account) }
  let(:domain_name) { "api-test-#{SecureRandom.hex(4)}.deskbolic.localhost" }

  describe ".seed" do
    it "creates API documentation portal, categories, endpoints, and all 7 locale translations" do
      Searchkick.callbacks(false) do
        expect {
          described_class.seed(account: account, domain: domain_name)
        }.not_to raise_error
      end

      account.with_shard do
        domain_record = Domain.find_by(value: domain_name)
        expect(domain_record).to be_present

        portal = HelpCenter::Portal.find_by(domain_id: domain_record.id)
        expect(portal).to be_present
        expect(portal.locales).to match_array(Core::SUPPORTED_LOCALES.map(&:to_s))
        expect(portal.translations.count).to eq(7)

        expect(portal.categories.count).to eq(17)
        
        # Verify Getting Started
        getting_started_cat = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: "en", name: "Getting Started" })
        expect(getting_started_cat).to be_present
        expect(getting_started_cat.translations.count).to eq(7)

        # Verify Conversations
        conv_cat = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: "en", name: "Conversations" })
        expect(conv_cat).to be_present
        expect(conv_cat).to be_api_reference
        expect(conv_cat.translations.count).to eq(7)

        # Check endpoints inside conversations category
        expect(conv_cat.articles.count).to be >= 5
        conv_list_art = conv_cat.articles.joins(:translations).find_by(help_center_article_translations: { locale: "en", title: "List Conversations" })
        expect(conv_list_art).to be_present
        expect(conv_list_art.configurations["api_method"]).to eq("GET")
        expect(conv_list_art.configurations["api_endpoint"]).to eq("/v1/conversations")
        expect(conv_list_art.translations.count).to eq(7)
      end
    end
  end
end

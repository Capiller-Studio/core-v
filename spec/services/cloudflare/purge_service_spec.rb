# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cloudflare::PurgeService do
  let(:account) { create(:account) }
  let(:contact_form) { create(:channel_contact_form, account: account) }
  let(:web_widget) { create(:channel_web_widget, account: account) }

  describe ".purge_contact_form" do
    it "constructs purge URLs for unlocalized and all Core::SUPPORTED_LOCALES endpoints" do
      urls_purged = nil
      allow(described_class).to receive(:purge_urls) do |urls|
        urls_purged = urls
        { success: true, purged: urls.size }
      end

      described_class.purge_contact_form(contact_form)

      base = described_class.widget_base_url
      expect(urls_purged).to include("#{base}/f/#{account.id}/#{contact_form.id}/embed.js")
      expect(urls_purged).to include("#{base}/f/#{account.id}/#{contact_form.id}")

      Core::SUPPORTED_LOCALES.each do |locale|
        expect(urls_purged).to include("#{base}/#{locale}/f/#{account.id}/#{contact_form.id}")
      end
    end
  end

  describe ".purge_web_widget" do
    it "constructs purge URLs for unlocalized and all Core::SUPPORTED_LOCALES endpoints" do
      urls_purged = nil
      allow(described_class).to receive(:purge_urls) do |urls|
        urls_purged = urls
        { success: true, purged: urls.size }
      end

      described_class.purge_web_widget(web_widget)

      base = described_class.widget_base_url
      expect(urls_purged).to include("#{base}/w/#{account.id}/#{web_widget.id}/embed.js")
      expect(urls_purged).to include("#{base}/w/#{account.id}/#{web_widget.id}")

      Core::SUPPORTED_LOCALES.each do |locale|
        expect(urls_purged).to include("#{base}/#{locale}/w/#{account.id}/#{web_widget.id}")
      end
    end
  end

  describe ".purge_urls" do
    context "when credentials are not set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("CLOUDFLARE_ZONE_ID").and_return(nil)
        allow(ENV).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return(nil)
      end

      it "gracefully skips without errors and returns skipped: true" do
        result = described_class.purge_urls(["https://widget.deskbolic.com/embed.js"])
        expect(result[:success]).to be true
        expect(result[:skipped]).to be true
        expect(result[:reason]).to eq(:missing_credentials)
      end
    end

    context "when credentials are set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("CLOUDFLARE_ZONE_ID").and_return("test-zone-123")
        allow(ENV).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return("test-token-456")
      end

      it "sends a POST request to Cloudflare purge cache endpoint" do
        urls = ["https://widget.deskbolic.com/f/1/2/embed.js"]
        fake_response = instance_double(Net::HTTPSuccess, is_a?: true, code: "200", body: { "success" => true }.to_json)

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(fake_response)

        result = described_class.purge_urls(urls)
        expect(result[:success]).to be true
        expect(result[:purged]).to eq(1)
      end
    end
  end
end

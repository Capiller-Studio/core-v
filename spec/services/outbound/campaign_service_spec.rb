# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outbound::CampaignService do
  before do
    ActionMailer::Base.deliveries.clear
  end

  describe ".send_email" do
    it "delivers outreach email when valid" do
      result = described_class.send_email(to: "alex@acme.com", name: "Alex", company: "Acme", competitor: "intercom")

      expect(result[:success]).to be(true)
      expect(result[:to]).to eq("alex@acme.com")
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(["alex@acme.com"])
      expect(mail.from).to eq(["ahsan@techbolic.com"])
    end

    it "does not deliver email when dry_run is true" do
      result = described_class.send_email(to: "alex@acme.com", name: "Alex", dry_run: true)

      expect(result[:success]).to be(true)
      expect(result[:dry_run]).to be(true)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "rejects invalid email address" do
      result = described_class.send_email(to: "not-an-email", name: "Bob")

      expect(result[:success]).to be(false)
      expect(result[:error]).to include("Invalid email format")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe ".send_batch" do
    let(:leads) do
      [
        { email: "alex@acme.com", name: "Alex", company: "Acme", competitor: "intercom" },
        { email: "sarah@beta.io", name: "Sarah", company: "Beta", competitor: "zendesk" },
        { email: "invalid-email", name: "Skip" },
        { email: "alex@acme.com", name: "Alex Duplicate" }
      ]
    end

    it "sends emails with deduplication and skips invalid emails" do
      result = described_class.send_batch(leads, delay_seconds: 0, dry_run: false)

      expect(result[:total]).to eq(4)
      expect(result[:sent]).to eq(2)
      expect(result[:skipped]).to eq(2)
      expect(ActionMailer::Base.deliveries.size).to eq(2)
    end

    it "simulates batch in dry_run mode without sending" do
      result = described_class.send_batch(leads, delay_seconds: 0, dry_run: true)

      expect(result[:total]).to eq(4)
      expect(result[:sent]).to eq(2)
      expect(result[:skipped]).to eq(2)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe ".send_from_csv" do
    let(:csv_file) { Tempfile.new(["leads", ".csv"]) }

    after do
      csv_file.close
      csv_file.unlink
    end

    it "parses CSV and sends batch" do
      csv_file.write("Email,Name,Company,Competitor\nlead1@example.com,John,Corp1,intercom\nlead2@example.com,Jane,Corp2,zendesk\n")
      csv_file.rewind

      result = described_class.send_from_csv(csv_file.path, delay_seconds: 0, dry_run: true)

      expect(result[:total]).to eq(2)
      expect(result[:sent]).to eq(2)
      expect(result[:dry_run]).to be(true)
    end

    it "raises error if CSV file does not exist" do
      expect {
        described_class.send_from_csv("/nonexistent/file.csv")
      }.to raise_error(ArgumentError, /CSV file not found/)
    end
  end

  describe ".preview" do
    it "returns subject and body previews without delivering" do
      preview = described_class.preview(to: "alex@acme.com", name: "Alex", company: "Acme", competitor: "intercom")

      expect(preview[:to]).to eq(["alex@acme.com"])
      expect(preview[:from]).to eq(["ahsan@techbolic.com"])
      expect(preview[:subject]).to include("Intercom")
      expect(preview[:html_part]).to include("Alex")
      expect(preview[:text_part]).to include("Capiller Rely")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end

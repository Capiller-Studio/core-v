# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutreachMailer, type: :mailer do
  describe "#outreach" do
    let(:email) { "lead@example.com" }

    it "renders email with correct sender, reply-to, and recipient" do
      mail = described_class.outreach(to: email, name: "Alex", company: "Acme")

      expect(mail.to).to eq(["lead@example.com"])
      expect(mail.from).to eq(["ahsan@techbolic.com"])
      expect(mail.reply_to).to eq(["ahsan@techbolic.com"])
      expect(mail.subject).to include("Acme")
    end

    it "tailors the subject and body when competitor is specified" do
      mail = described_class.outreach(to: email, name: "Sarah", company: "TechCorp", competitor: "intercom")

      expect(mail.subject).to include("Intercom")
      expect(mail.subject).to include("TechCorp")

      html_body = mail.html_part.body.to_s
      expect(html_body).to include("Sarah")
      expect(html_body).to include("Intercom")
      expect(html_body).to include("deskbolic.com/comparisons/intercom")
      expect(html_body).to include("14-day free trial")
      expect(html_body).to include("https://deskbolic.app/register")
      expect(html_body).to include("ahsan@techbolic.com")

      text_body = mail.text_part.body.to_s
      expect(text_body).to include("Sarah")
      expect(text_body).to include("Intercom")
      expect(text_body).to include("https://deskbolic.app/register")
    end

    it "works without optional parameters" do
      mail = described_class.outreach(to: email)

      expect(mail.to).to eq(["lead@example.com"])
      expect(mail.subject).to be_present
      expect(mail.html_part.body.to_s).to include("Hi there,")
      expect(mail.text_part.body.to_s).to include("Hi there,")
    end

    it "includes custom_hook when provided" do
      mail = described_class.outreach(to: email, name: "John", custom_hook: "Loved your recent Product Hunt launch!")

      expect(mail.html_part.body.to_s).to include("Loved your recent Product Hunt launch!")
      expect(mail.text_part.body.to_s).to include("Loved your recent Product Hunt launch!")
    end
  end
end

require 'rails_helper'

RSpec.describe Seeds::EmailTemplateSeeder do
  let(:account) { create(:account, locale: 'en') }

  describe '#seed' do
    it 'creates a default layout and system templates' do
      expect {
        described_class.seed(account)
      }.to change { account.email_template_layouts.count }.by(1)
       .and change { account.email_templates.count }.by(EmailTemplate::SYSTEM_TEMPLATES.count)

      account.with_shard do
        layout = account.email_template_layouts.find_by(name: 'Default Layout')
        expect(layout).not_to be_nil
        expect(layout.translations.exists?(locale: 'en')).to be true

        EmailTemplate::SYSTEM_TEMPLATES.each do |template_name|
          template = account.email_templates.find_by(name: template_name)
          expect(template).not_to be_nil
          expect(template.email_template_layout).to eq(layout)
          expect(template.translations.exists?(locale: 'en')).to be true
        end
      end
    end

    it 'is idempotent' do
      described_class.seed(account)

      expect {
        described_class.seed(account)
      }.to change { account.email_template_layouts.count }.by(0)
       .and change { account.email_templates.count }.by(0)
    end
  end
end

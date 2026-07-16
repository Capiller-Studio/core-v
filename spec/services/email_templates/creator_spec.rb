require 'rails_helper'

RSpec.describe EmailTemplates::Creator do
  let(:account) { double('Account', locale: 'en') }
  let(:service) { described_class.new(account: account, name: 'Welcome', template_type: 'welcome_email') }

  describe '#call' do
    let(:template) { double('EmailTemplate') }
    let(:translations_assoc) { double('TranslationsAssoc') }

    before do
      allow(account).to receive(:with_shard).and_yield
      allow(ShardRecord).to receive(:transaction).and_yield
    end

    it 'creates email template and translation' do
      expect(EmailTemplate).to receive(:new).with(
        account: account,
        name: 'Welcome',
        template_type: 'welcome_email',
        status: :inactive,
        email_template_layout: nil
      ).and_return(template)

      allow(template).to receive(:save!)
      allow(template).to receive(:translations).and_return(translations_assoc)

      allow(I18n).to receive(:t).with(
        "seeds.email_templates.welcome_email.subject",
        locale: 'en',
        default: 'Welcome Email'
      ).and_return('Welcome Subject')

      expect(translations_assoc).to receive(:create!).with(
        hash_including(
          locale: 'en',
          draft_subject: 'Welcome Subject'
        )
      )

      expect(service.call).to eq(template)
    end
  end
end

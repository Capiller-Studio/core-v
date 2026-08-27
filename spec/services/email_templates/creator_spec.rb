# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailTemplates::Creator do
  let(:account) { create(:account, locale: 'es') }
  let(:service) { described_class.new(account: account, name: 'Welcome', template_type: 'welcome_email') }

  describe '#call' do
    it 'creates the email template and draft translation for the account locale' do
      account.with_shard do
        template = service.call

        expect(template).to be_persisted
        expect(template.name).to eq('Welcome')
        expect(template.template_type).to eq('welcome_email')
        expect(template.status).to eq('inactive')

        expect(template.translations.count).to eq(1)
        expect(template.translations.first.locale).to eq('es')

        translation = template.translations.first
        expect(translation.draft_subject).to be_present
        expect(translation.draft_body).to be_present
      end
    end
  end
end

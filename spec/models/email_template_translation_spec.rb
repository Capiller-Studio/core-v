# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailTemplateTranslation, type: :model do
  let(:account) { create(:account) }
  let(:email_template) do
    account.with_shard do
      create(:email_template, account: account, status: :inactive)
    end
  end

  describe 'validations and associations' do
    it 'validates uniqueness of locale scoped to email_template_id' do
      account.with_shard do
        translation = email_template.translations.find_or_create_by!(locale: 'en')
        duplicate = EmailTemplateTranslation.new(email_template: email_template, locale: 'en')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:locale]).to include('has already been taken')
      end
    end
  end
end

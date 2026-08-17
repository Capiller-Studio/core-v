# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailTemplateLayoutTranslation, type: :model do
  let(:account) { create(:account) }
  let(:layout) do
    account.with_shard do
      create(:email_template_layout, account: account)
    end
  end

  describe 'Associations and Validations' do
    it { is_expected.to belong_to(:email_template_layout) }
    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:body) }

    it 'validates uniqueness of locale scoped to layout' do
      account.with_shard do
        described_class.create!(email_template_layout: layout, locale: 'es', body: '<body>{{ content }}</body>')
        dup = described_class.new(email_template_layout: layout, locale: 'es', body: '<body>{{ content }}</body>')

        expect(dup).not_to be_valid
        expect(dup.errors[:locale]).to include('has already been taken')
      end
    end
  end
end

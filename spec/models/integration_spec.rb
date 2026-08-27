# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integration, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:webhook_deliveries) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:provider) }

    describe 'provider uniqueness' do
      let(:account) { create(:account) }

      it 'allows multiple webhook integrations for the same account' do
        account.with_shard do
          webhook1 = create(:integration, account: account, provider: :webhook, settings: { 'url' => 'https://example1.com' })
          webhook2 = build(:integration, account: account, provider: :webhook, settings: { 'url' => 'https://example2.com' })

          expect(webhook2).to be_valid
          expect { webhook2.save! }.not_to raise_error
        end
      end

      it 'does not allow duplicate non-webhook integrations for the same account' do
        account.with_shard do
          create(:integration, account: account, provider: :slack, settings: { 'webhook_url' => 'https://hooks.slack.com/1' })
          duplicate_slack = build(:integration, account: account, provider: :slack, settings: { 'webhook_url' => 'https://hooks.slack.com/2' })

          expect(duplicate_slack).not_to be_valid
          expect(duplicate_slack.errors[:provider]).to be_present
        end
      end
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:provider).with_values(slack: 0, google_translate: 1, webhook: 2) }
  end
end

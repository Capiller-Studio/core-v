# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integration, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:webhook_deliveries) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:status) }

    describe 'provider uniqueness' do
      let(:account) { create(:account) }

      it 'allows multiple webhook integrations for the same account' do
        account.with_shard do
          webhook1 = create(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'https://example1.com' })
          webhook2 = build(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'https://example2.com' })

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

    describe 'webhook_url safety validations' do
      let(:account) { create(:account) }

      before do
        allow(Resolv).to receive(:getaddresses).and_call_original
        allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
      end

      it 'allows legitimate public HTTPS endpoints' do
        integration = build(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'https://example.com/webhook' })
        expect(integration).to be_valid
      end

      it 'rejects localhost and 127.0.0.1' do
        integration = build(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'http://localhost:3000/webhook' })
        expect(integration).not_to be_valid
        expect(integration.errors[:base].join).to include('cannot point to localhost or internal network spaces')

        integration2 = build(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'http://127.0.0.1:8080/webhook' })
        expect(integration2).not_to be_valid
        expect(integration2.errors[:base].join).to include('cannot point to localhost or internal network spaces')
      end

      it 'rejects cloud metadata IP' do
        integration = build(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'http://169.254.169.254/latest/meta-data' })
        expect(integration).not_to be_valid
        expect(integration.errors[:base].join).to include('cannot point to internal or private IP addresses')
      end

      it 'rejects private RFC1918 subnets' do
        integration = build(:integration, account: account, provider: :webhook, settings: { 'webhook_url' => 'http://10.0.0.1/hook' })
        expect(integration).not_to be_valid
        expect(integration.errors[:base].join).to include('cannot point to internal or private IP addresses')
      end
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:provider).with_values(slack: 0, google_translate: 1, webhook: 2) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, disabled: 1) }
  end
end

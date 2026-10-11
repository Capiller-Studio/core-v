# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomerDevice, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:customer_inbox) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:platform).with_values(ios: 0, android: 1) }
    it { is_expected.to define_enum_for(:push_provider).with_values(apns: 0, fcm: 1) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, invalid_token: 1) }
  end

  describe 'Validations' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:customer) { create(:customer, account: account) }
    let(:customer_inbox) { create(:customer_inbox, inbox: inbox, customer: customer) }

    subject do
      account.with_shard do
        create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox)
      end
    end

    it { is_expected.to validate_presence_of(:push_token) }

    it 'validates uniqueness of push_token scoped to inbox_id' do
      account.with_shard do
        duplicate = build(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, push_token: subject.push_token)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:push_token]).to be_present
      end
    end

    it 'allows same push_token for different inboxes' do
      other_inbox = create(:inbox, account: account)
      other_ci = create(:customer_inbox, inbox: other_inbox, customer: customer)
      account.with_shard do
        different_inbox_device = build(:customer_device, account: account, inbox: other_inbox, customer: customer, customer_inbox: other_ci, push_token: subject.push_token)
        expect(different_inbox_device).to be_valid
      end
    end
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:customer) { create(:customer, account: account) }
    let(:customer_inbox) { create(:customer_inbox, inbox: inbox, customer: customer) }

    it 'filters active devices with .active scope' do
      account.with_shard do
        active_dev = create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, status: :active)
        invalid_dev = create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, status: :invalid_token)

        expect(described_class.active).to include(active_dev)
        expect(described_class.active).not_to include(invalid_dev)
      end
    end
  end

  describe '#invalidate!' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:customer) { create(:customer, account: account) }
    let(:customer_inbox) { create(:customer_inbox, inbox: inbox, customer: customer) }

    it 'marks status as invalid_token and records error details and timestamp' do
      device = account.with_shard do
        create(:customer_device, account: account, inbox: inbox, customer: customer, customer_inbox: customer_inbox, status: :active)
      end

      device.invalidate!('BadDeviceToken')
      device.reload

      expect(device.status).to eq('invalid_token')
      expect(device.data['last_error']).to eq('BadDeviceToken')
      expect(device.data['invalidated_at']).to be_present
    end
  end
end

require 'rails_helper'

RSpec.describe Customer, type: :model do
  subject { build(:customer) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:address) }
    it { is_expected.to have_many(:customer_inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:conversation_members).dependent(:destroy) }
    it { is_expected.to have_many(:conversations).through(:conversation_members) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
    it { is_expected.to define_enum_for(:gender).with_values(male: 0, female: 1) }
    it { is_expected.to define_enum_for(:customer_type).with_values(guest: 0, customer: 1) }
  end

  describe '#event_payload' do
    let(:customer) { create(:customer) }

    it 'returns basic customer data' do
      payload = customer.event_payload
      expect(payload[:id]).to eq(customer.id)
      expect(payload[:created_at]).to be_present
    end
  end
end

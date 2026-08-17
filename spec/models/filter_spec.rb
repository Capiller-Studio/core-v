# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Filter, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:filter_type).with_values(conversation: 0) }
  end

  describe 'creation' do
    it 'creates a filter within account shard' do
      filter = account.with_shard do
        create(:filter, account: account, user: user, name: 'Urgent Inbox', conditions: { 'priority' => 'urgent' })
      end

      expect(filter).to be_persisted
      expect(filter.name).to eq('Urgent Inbox')
      expect(filter.conditions).to eq({ 'priority' => 'urgent' })
    end
  end
end

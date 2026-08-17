# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Note, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:visibility).with_values(personal: 0, global: 1) }
  end

  describe 'creation' do
    it 'creates a note on a conversation within shard' do
      note = account.with_shard do
        create(:note, account: account, user: user, resource: conversation, content: 'Customer called about refund')
      end

      expect(note).to be_persisted
      expect(note.content).to eq('Customer called about refund')
      expect(note.personal?).to be(true)
    end
  end
end

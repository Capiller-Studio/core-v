# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxUser, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'creation' do
    it 'creates an inbox user association within shard' do
      iu = account.with_shard do
        described_class.create!(inbox: inbox, user: user)
      end

      expect(iu).to be_persisted
      expect(iu.inbox).to eq(inbox)
      expect(iu.user).to eq(user)
    end
  end
end

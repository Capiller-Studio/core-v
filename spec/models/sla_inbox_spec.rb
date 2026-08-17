# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlaInbox, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:sla_policy) { create(:sla_policy, account: account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:sla_policy) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'creation' do
    it 'links sla_policy and inbox within account shard' do
      sla_inbox = account.with_shard do
        described_class.create!(account: account, sla_policy: sla_policy, inbox: inbox)
      end

      expect(sla_inbox).to be_persisted
      expect(sla_inbox.sla_policy).to eq(sla_policy)
      expect(sla_inbox.inbox).to eq(inbox)
    end
  end
end

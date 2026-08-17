# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Routable, type: :model do
  let(:account) { create(:account) }

  describe 'GlobalRouting lifecycle' do
    it 'creates a GlobalRouting record on save and deletes on destroy' do
      email_channel = account.with_shard do
        create(:channel_email, account: account, email: "support-#{SecureRandom.hex(4)}@example.com")
      end

      routing = GlobalRouting.find_by(
        route_type: 'email',
        route_value: email_channel.routing_identifier
      )

      expect(routing).to be_present
      expect(routing.account_id).to eq(account.id)
      expect(routing.shard_key).to eq(account.shard_key)

      account.with_shard do
        email_channel.destroy
      end

      expect(GlobalRouting.find_by(id: routing.id)).to be_nil
    end
  end
end

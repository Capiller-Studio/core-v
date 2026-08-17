# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reauthorizable, type: :model do
  let(:account) { create(:account) }
  let(:channel) do
    account.with_shard do
      create(:channel_facebook_page, account: account)
    end
  end

  before do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks).and_return(true)
    allow_any_instance_of(Channel::FacebookPage).to receive(:unsubscribe_from_webhooks).and_return(true)
    stub_const('SystemMailer', double('SystemMailer', channel_reauthorization_required: double(deliver_later: true)))
    channel.reauthorized!
  end

  after do
    channel.reauthorized!
  end

  describe '#authorization_error! and #reauthorized!' do
    it 'increments authorization error count and triggers alert at threshold' do
      expect(channel.reauthorization_required?).to be(false)

      channel.authorization_error!
      expect(channel.authorization_error_count).to eq(1)
      expect(channel.reauthorization_required?).to be(false)

      channel.authorization_error!
      channel.authorization_error!

      expect(channel.authorization_error_count).to eq(3)
      expect(channel.reauthorization_required?).to be(true)
    end

    it 'clears authorization errors and flags upon reauthorized!' do
      3.times { channel.authorization_error! }
      expect(channel.reauthorization_required?).to be(true)

      channel.reauthorized!
      expect(channel.authorization_error_count).to eq(0)
      expect(channel.reauthorization_required?).to be(false)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::SyncTemplatesWorker, type: :worker do
  let(:account) { double('Account', id: 'acc_123') }
  let(:channel) { double('Channel::Whatsapp', id: 'chan_123') }

  describe '#perform' do
    it 'syncs templates for a single channel when account and channel ids provided' do
      allow(Account).to receive(:find_by).with(id: 'acc_123').and_return(account)
      allow(account).to receive(:with_shard).and_yield
      allow(Channel::Whatsapp).to receive(:find_by).with(id: 'chan_123').and_return(channel)

      expect(channel).to receive(:sync_templates)

      described_class.new.perform('acc_123', 'chan_123')
    end

    it 'gracefully returns when account not found' do
      allow(Account).to receive(:find_by).with(id: 'acc_unknown').and_return(nil)
      expect(Channel::Whatsapp).not_to receive(:find_by)

      described_class.new.perform('acc_unknown', 'chan_123')
    end

    it 'enqueues individual sync jobs for each active whatsapp channel across accounts' do
      allow(Account).to receive(:find_each).and_yield(account)
      allow(account).to receive(:with_shard).and_yield
      active_relation = double('ActiveRelation')
      allow(Channel::Whatsapp).to receive(:where).with(status: :active).and_return(active_relation)
      allow(active_relation).to receive(:find_each).and_yield(channel)

      expect(described_class).to receive(:perform_async).with('acc_123', 'chan_123')

      described_class.new.perform
    end
  end
end

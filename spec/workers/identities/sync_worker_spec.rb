# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Identities::SyncWorker, type: :worker do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account, external_id: 'ext-123') }
  let(:identity_source) { create(:identity_source, account: account, source_type: :api) }

  describe '#perform' do
    it 'creates a custom_api identity and calls Identities::ApiFetcher' do
      expect(Identities::ApiFetcher).to receive(:call) do |args|
        expect(args[:identity].customer_id).to eq(customer.id)
        expect(args[:identity].identity_source_id).to eq(identity_source.id)
      end

      expect {
        described_class.new.perform(customer.id, identity_source.id)
      }.to change { account.with_shard { Identity.count } }.by(1)

      identity = account.with_shard { Identity.find_by(customer_id: customer.id) }
      expect(identity.identity_type).to eq('custom_api')
      expect(identity.external_id).to eq('ext-123')
    end

    it 'returns early if identity already exists' do
      create(:identity,
        account: account,
        customer: customer,
        identity_source: identity_source,
        identity_type: :custom_api
      )

      expect(Identities::ApiFetcher).not_to receive(:call)

      expect {
        described_class.new.perform(customer.id, identity_source.id)
      }.not_to change(Identity, :count)
    end

    it 'returns early if customer or identity_source is missing' do
      expect(Identities::ApiFetcher).not_to receive(:call)

      described_class.new.perform(SecureRandom.uuid, identity_source.id)
    end
  end
end

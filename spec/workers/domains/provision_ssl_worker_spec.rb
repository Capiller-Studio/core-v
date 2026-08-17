# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Domains::ProvisionSslWorker, type: :worker do
  let(:account) { create(:account) }
  let(:domain) { create(:domain, :custom, account: account, dns_status: :dns_verified, ssl_status: :ssl_none) }

  describe '#perform' do
    it 'updates ssl_status to ssl_pending for verified domains' do
      described_class.new.perform(domain.id)

      domain.reload
      expect(domain.ssl_status).to eq('ssl_pending')
    end

    it 'returns early if DNS is not verified' do
      domain.update_columns(dns_status: :dns_pending)

      described_class.new.perform(domain.id)

      domain.reload
      expect(domain.ssl_status).to eq('ssl_none')
    end

    it 'returns early if SSL is already active' do
      domain.update_columns(ssl_status: :ssl_active)

      described_class.new.perform(domain.id)

      domain.reload
      expect(domain.ssl_status).to eq('ssl_active')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Domains::DnsVerificationWorker, type: :worker do
  let(:account) { create(:account) }
  let(:domain) { create(:domain, :custom, account: account, dns_status: :dns_pending) }

  describe '#perform' do
    it 'calls Domains::VerifyDns for unverified custom domains' do
      expect(Domains::VerifyDns).to receive(:call).with(domain: domain)

      described_class.new.perform(domain.id)
    end

    it 'returns early if domain is already verified' do
      domain.update_columns(dns_status: :dns_verified)
      expect(Domains::VerifyDns).not_to receive(:call)

      described_class.new.perform(domain.id)
    end

    it 'returns early if domain is system default rather than custom' do
      domain.update_columns(domain_type: :subdomain)
      expect(Domains::VerifyDns).not_to receive(:call)

      described_class.new.perform(domain.id)
    end
  end
end

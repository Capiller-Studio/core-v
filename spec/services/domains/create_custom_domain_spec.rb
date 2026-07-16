require 'rails_helper'

RSpec.describe Domains::CreateCustomDomain do
  let(:account) { double('Account') }
  let(:service) { described_class.new(account: account, value: 'example.com', name: 'Example') }

  describe '#call' do
    let(:domain) { double('Domain', id: 1, persisted?: true) }

    before do
      stub_const('Domain', double('DomainClass'))
      stub_const('Domains::DnsVerificationWorker', double('DnsVerificationWorker'))
    end

    it 'creates a custom domain and queues verification' do
      expect(Domain).to receive(:create!).with(
        account: account,
        value: 'example.com',
        name: 'Example',
        domain_type: :custom,
        status: :active
      ).and_return(domain)

      expect(Domains::DnsVerificationWorker).to receive(:perform_async).with(1)

      expect(service.call).to eq(domain)
    end

    it 'does not queue verification if domain is not persisted' do
      allow(Domain).to receive(:create!).and_return(double('Domain', persisted?: false))
      expect(Domains::DnsVerificationWorker).not_to receive(:perform_async)
      
      service.call
    end
  end
end

require 'rails_helper'

RSpec.describe Domains::CreateSubdomain do
  let(:account) { double('Account') }
  let(:service) { described_class.new(account: account, slug: 'help', name: 'Help Portal') }

  describe '#call' do
    let(:domain) { double('Domain') }

    before do
      stub_const('Domain', double('DomainClass'))
    end

    it 'creates a subdomain' do
      expect(Domain).to receive(:create!).with(
        account: account,
        value: 'help',
        name: 'Help Portal',
        domain_type: :subdomain,
        status: :active
      ).and_return(domain)

      expect(service.call).to eq(domain)
    end
  end
end

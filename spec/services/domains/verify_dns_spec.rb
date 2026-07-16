require 'rails_helper'

RSpec.describe Domains::VerifyDns do
  let(:domain) { double('Domain', id: 1, value: 'example.com', subdomain?: false) }
  let(:service) { described_class.new(domain: domain) }

  before do
    stub_const('Domain::CNAME_TARGET', 'cname.deskbolic.com')
    stub_const('Domains::ProvisionSslWorker', double('ProvisionSslWorker'))
  end

  describe '#call' do
    it 'returns true immediately if domain is a subdomain' do
      allow(domain).to receive(:subdomain?).and_return(true)
      expect(domain).not_to receive(:update!)
      expect(service.call).to be true
    end

    context 'when DNS verification succeeds' do
      let(:resolver) { double('Resolv::DNS') }
      let(:cname_record) { double('Resource', name: double(to_s: 'CNAME.deskbolic.com')) }

      before do
        allow(Resolv::DNS).to receive(:new).and_return(resolver)
        allow(resolver).to receive(:getresources).with('example.com', Resolv::DNS::Resource::IN::CNAME).and_return([cname_record])
        allow(resolver).to receive(:close)
      end

      it 'updates status to verified and queues ssl worker' do
        expect(domain).to receive(:update!).with(hash_including(dns_status: :dns_pending))
        expect(domain).to receive(:update!).with(hash_including(dns_status: :dns_verified))
        
        expect(Domains::ProvisionSslWorker).to receive(:perform_async).with(1)
        
        expect(service.call).to be true
      end
    end

    context 'when DNS verification fails' do
      let(:resolver) { double('Resolv::DNS') }
      let(:cname_record) { double('Resource', name: double(to_s: 'wrong.target.com')) }

      before do
        allow(Resolv::DNS).to receive(:new).and_return(resolver)
        allow(resolver).to receive(:getresources).with('example.com', Resolv::DNS::Resource::IN::CNAME).and_return([cname_record])
        allow(resolver).to receive(:close)
      end

      it 'updates status to failed and does not queue ssl worker' do
        expect(domain).to receive(:update!).with(hash_including(dns_status: :dns_pending))
        expect(domain).to receive(:update!).with(hash_including(dns_status: :dns_failed))
        
        expect(Domains::ProvisionSslWorker).not_to receive(:perform_async)
        
        expect(service.call).to be false
      end
    end

    context 'when DNS resolution raises error' do
      let(:resolver) { double('Resolv::DNS') }

      before do
        allow(Resolv::DNS).to receive(:new).and_return(resolver)
        allow(resolver).to receive(:getresources).and_raise(Resolv::ResolvError)
        allow(resolver).to receive(:close)
      end

      it 'rescues error, updates status to failed' do
        expect(domain).to receive(:update!).with(hash_including(dns_status: :dns_pending))
        expect(domain).to receive(:update!).with(hash_including(dns_status: :dns_failed))
        
        expect(service.call).to be false
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Identities::AutomationManager do
  let(:account) { double('Account') }
  let(:customer) { double('Customer', id: 5, account: account) }
  let(:service) { described_class.new(customer: customer, inbox: nil, external_id: nil) }

  describe '#call' do
    let(:sources_scope) { double('SourcesScope') }
    let(:api_scope) { double('ApiScope') }
    let(:identities_scope) { double('IdentitiesScope') }
    let(:source) { double('IdentitySource', id: 10) }

    before do
      allow(account).to receive(:identity_sources).and_return(sources_scope)
      allow(sources_scope).to receive(:api).and_return(api_scope)
      allow(account).to receive(:identities).and_return(identities_scope)
      
      stub_const('Identities::SyncWorker', double('SyncWorker'))
    end

    it 'triggers sync for missing identities' do
      allow(api_scope).to receive(:find_each).and_yield(source)
      
      expect(identities_scope).to receive(:exists?).with(
        customer: customer, 
        identity_source: source, 
        identity_type: :custom_api
      ).and_return(false)

      expect(Identities::SyncWorker).to receive(:perform_async).with(5, 10)

      service.call
    end

    it 'skips sync if identity already exists' do
      allow(api_scope).to receive(:find_each).and_yield(source)
      
      expect(identities_scope).to receive(:exists?).with(
        customer: customer, 
        identity_source: source, 
        identity_type: :custom_api
      ).and_return(true)

      expect(Identities::SyncWorker).not_to receive(:perform_async)

      service.call
    end
  end
end

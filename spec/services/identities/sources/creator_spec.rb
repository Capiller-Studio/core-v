require 'rails_helper'

RSpec.describe Identities::Sources::Creator do
  let(:account) { double('Account') }
  let(:params) do
    {
      name: 'My API',
      source_url: 'http://api.com/{{customer.id}}',
      headers: { 'Auth' => 'Bearer {{identity.external_id}}' },
      query_params: { 'q' => 'test' }
    }
  end
  let(:service) { described_class.new(account: account, params: params) }

  describe '#call' do
    let(:sources_scope) { double('SourcesScope') }
    let(:source) { double('IdentitySource') }

    before do
      allow(account).to receive(:identity_sources).and_return(sources_scope)
      allow(ActiveRecord::Base).to receive(:transaction).and_yield
    end

    it 'creates identity source if valid liquid syntax' do
      expect(sources_scope).to receive(:create!).with(
        name: 'My API',
        source_url: 'http://api.com/{{customer.id}}',
        description: nil,
        source_type: :api,
        configurations: {},
        headers: { 'Auth' => 'Bearer {{identity.external_id}}' },
        response_mapping: {},
        params: { 'q' => 'test' }
      ).and_return(source)

      expect(service.call).to eq(source)
    end

    it 'adds error if invalid liquid syntax' do
      params[:source_url] = 'http://api.com/{{customer.id' # Missing closing braces
      
      errors = double('Errors')
      allow(service).to receive(:errors).and_return(errors)
      expect(errors).to receive(:add).with(:base, /Invalid Liquid Syntax/)
      
      expect(service.call).to be_nil
    end

    it 'adds error on ActiveRecord error' do
      allow(sources_scope).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      
      errors = double('Errors')
      allow(service).to receive(:errors).and_return(errors)
      expect(errors).to receive(:add).with(:base, anything)
      
      expect(service.call).to be_nil
    end
  end
end

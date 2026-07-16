require 'rails_helper'

RSpec.describe Identities::ApiFetcher do
  let(:customer) { double('Customer', id: 1, email: 'test@example.com', first_name: 'Test', last_name: 'User', name: 'Test User', identifier: 'c1', full_phone_number: '123', external_id: 'e1') }
  let(:identity_source) { double('IdentitySource', source_url: 'http://api.com/{{customer.id}}', headers: { 'Authorization' => 'Bearer {{identity.identifier}}' }, params: { 'q' => 'test' }) }
  let(:identity) { double('Identity', id: 10, identifier: 'id_123', external_id: 'ex_123', custom_api?: true, identity_source: identity_source, customer: customer) }
  let(:service) { described_class.new(identity: identity) }

  describe '#call' do
    before do
      stub_const('Identities::Mapper', double('MapperClass'))
      allow(identity).to receive(:update!)
    end

    it 'raises error if identity is not custom api' do
      allow(identity).to receive(:custom_api?).and_return(false)
      expect { service.call }.not_to raise_error
      expect(identity).to have_received(:update!).with(raw_response: hash_including(error: /IdentitySource missing or not an API type/))
    end

    it 'fetches api, maps data, and updates identity' do
      response = double('Response', parsed_response: { "data" => "test" })
      
      expect(HTTParty).to receive(:get).with(
        'http://api.com/1',
        headers: { 'Authorization' => 'Bearer id_123' },
        query: { 'q' => 'test' },
        timeout: 10
      ).and_return(response)

      expect(Identities::Mapper).to receive(:call).with(
        identity_source: identity_source,
        raw_response: { "data" => "test" }
      ).and_return({ first_name: 'Mapped', custom_attributes: { "role" => "admin" } })

      expect(identity).to receive(:update!).with(
        hash_including(
          raw_response: { "data" => "test" },
          first_name: 'Mapped',
          custom_attributes: { "role" => "admin" }
        )
      )

      expect(service.call).to eq(identity)
    end

    it 'handles errors by saving raw_response error' do
      allow(HTTParty).to receive(:get).and_raise(StandardError.new('API Down'))
      
      expect(identity).to receive(:update!).with(raw_response: { error: 'API Down' })
      expect(Rails.logger).to receive(:error).with(/Identities::ApiFetcher Error/)

      expect { service.call }.not_to raise_error
    end
  end
end

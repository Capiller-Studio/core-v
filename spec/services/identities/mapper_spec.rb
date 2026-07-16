require 'rails_helper'

RSpec.describe Identities::Mapper do
  describe '#call' do
    let(:identity_source) { double('IdentitySource', response_mapping: mapping) }
    let(:raw_response) { { "user" => { "name" => "John", "admin" => true }, "metadata" => { "tier" => "gold" }, "arr" => [{ "id" => 1 }] } }
    let(:service) { described_class.new(identity_source: identity_source, raw_response: raw_response) }

    context 'with valid mapping' do
      let(:mapping) do
        {
          "name" => "user.name",
          "custom_attributes" => {
            "tier" => "metadata.tier",
            "is_admin" => "user.admin",
            "first_item_id" => "arr.[0].id"
          }
        }
      end

      it 'maps standard and custom fields' do
        result = service.call
        
        expect(result[:name]).to eq("John")
        expect(result[:custom_attributes]["tier"]).to eq("gold")
        expect(result[:custom_attributes]["is_admin"]).to be true
        expect(result[:custom_attributes]["first_item_id"]).to eq(1)
      end
    end

    context 'with flat mapping for custom attributes' do
      let(:mapping) do
        {
          "name" => "user.name",
          "tier" => "metadata.tier" # Flat mapping instead of nested inside custom_attributes
        }
      end

      it 'extracts non-standard fields as custom attributes' do
        result = service.call
        
        expect(result[:name]).to eq("John")
        expect(result[:custom_attributes]["tier"]).to eq("gold")
        # Standard field "name" should not be duplicated in custom_attributes
        expect(result[:custom_attributes]).not_to have_key("name")
      end
    end

    context 'with empty mapping or errors' do
      let(:mapping) { {} }

      it 'returns empty hash if mapping is blank' do
        expect(service.call).to eq({})
      end

      it 'handles JSON parser error if string' do
        service = described_class.new(identity_source: double(response_mapping: { "a" => "b" }), raw_response: "invalid { json")
        expect(service.call).to eq({})
      end
    end
  end
end

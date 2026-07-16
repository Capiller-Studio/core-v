require 'rails_helper'

RSpec.describe Automations::AutomationValidator do
  let(:service) { described_class.new(conditions: conditions) }

  describe '#valid?' do
    context 'when conditions is not a hash' do
      let(:conditions) { "not a hash" }
      it 'returns false' do
        expect(service.valid?).to be false
        expect(service.errors).to include("conditions must be a JSON object")
      end
    end

    context 'when top operator is invalid' do
      let(:conditions) { { "operator" => "INVALID", "groups" => [] } }
      it 'returns false' do
        expect(service.valid?).to be false
        expect(service.errors).to include("conditions.operator must be AND or OR")
      end
    end

    context 'with invalid attribute' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "secret_token", "operator" => "equals", "value" => "123" }
              ]
            }
          ]
        }
      end
      it 'returns false' do
        expect(service.valid?).to be false
        expect(service.errors.first).to match(/is not allowed/)
      end
    end

    context 'with invalid condition operator' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "status", "operator" => "magic", "value" => "open" }
              ]
            }
          ]
        }
      end
      it 'returns false' do
        expect(service.valid?).to be false
        expect(service.errors.first).to match(/is not valid/)
      end
    end

    context 'with missing value for operator' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "status", "operator" => "equals" }
              ]
            }
          ]
        }
      end
      it 'returns false' do
        expect(service.valid?).to be false
        expect(service.errors.first).to match(/value is required for operator 'equals'/)
      end
    end

    context 'with valid conditions' do
      let(:conditions) do
        {
          "operator" => "AND",
          "groups" => [
            {
              "operator" => "OR",
              "conditions" => [
                { "attribute" => "status", "operator" => "equals", "value" => "open" },
                { "attribute" => "custom_field.order_id", "operator" => "is_present" }
              ]
            }
          ]
        }
      end
      it 'returns true' do
        expect(service.valid?).to be true
      end
    end
  end
end

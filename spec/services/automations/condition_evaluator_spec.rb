require 'rails_helper'

RSpec.describe Automations::ConditionEvaluator do
  let(:payload) do
    {
      "status" => "active",
      "priority" => "high",
      "tags" => ["urgent", "bug"],
      "inbox" => { "name" => "Support" },
      "data" => { "order_id" => "12345" },
      "created_at" => 5.days.ago.to_s
    }
  end

  let(:service) { described_class.new(conditions: conditions, payload: payload) }

  describe '#call' do
    context 'when conditions are empty' do
      let(:conditions) { {} }
      it 'returns true' do
        expect(service.call).to be true
      end
    end

    context 'when evaluating basic attributes' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "status", "operator" => "equals", "value" => "active" }
              ]
            }
          ]
        }
      end

      it 'returns true on match' do
        expect(service.call).to be true
      end

      it 'returns false on mismatch' do
        conditions["groups"][0]["conditions"][0]["value"] = "closed"
        expect(service.call).to be false
      end
    end

    context 'when evaluating nested attributes' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "inbox.name", "operator" => "equals", "value" => "Support" }
              ]
            }
          ]
        }
      end

      it 'resolves dotted path' do
        expect(service.call).to be true
      end
    end

    context 'when evaluating custom fields' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "custom_field.order_id", "operator" => "equals", "value" => "12345" }
              ]
            }
          ]
        }
      end

      it 'resolves from data hash' do
        expect(service.call).to be true
      end
    end

    context 'when evaluating arrays with contains' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "tags", "operator" => "contains", "value" => "bug" }
              ]
            }
          ]
        }
      end

      it 'returns true if array includes value' do
        expect(service.call).to be true
      end
    end

    context 'when evaluating days_before' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "created_at", "operator" => "days_before", "value" => "3" }
              ]
            }
          ]
        }
      end

      it 'returns true if date is older than N days' do
        expect(service.call).to be true
      end

      it 'returns false if date is newer than N days' do
        payload["created_at"] = 1.day.ago.to_s
        expect(service.call).to be false
      end
    end
    
    context 'with OR operator' do
      let(:conditions) do
        {
          "operator" => "OR",
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "status", "operator" => "equals", "value" => "closed" }
              ]
            },
            {
              "conditions" => [
                { "attribute" => "priority", "operator" => "equals", "value" => "high" }
              ]
            }
          ]
        }
      end

      it 'returns true if any group matches' do
        expect(service.call).to be true
      end
    end
  end
end

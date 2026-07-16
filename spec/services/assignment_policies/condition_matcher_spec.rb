require 'rails_helper'

RSpec.describe AssignmentPolicies::ConditionMatcher do
  let(:policy) { double('Policy', conditions: conditions) }
  let(:conversation) do
    double('Conversation', 
      status: 'open', 
      priority: 'high',
      source: 'api',
      locale: 'en',
      title: 'Help',
      identifier: 'ID-123',
      inbox_id: 1,
      inbox: double('Inbox', name: 'Support', channel_type: 'web'),
      team_id: 2,
      team: double('Team', name: 'Tier 1'),
      assignee: double('Assignee', id: 3, name: 'Alice', email: 'alice@example.com'),
      customers: [double('Customer', email: 'cust@example.com', name: 'Bob', locale: 'en', customer_type: 'lead')],
      data: { 'custom_id' => 'XYZ' }
    )
  end
  
  let(:service) { described_class.new(policy: policy, conversation: conversation) }

  describe '#call' do
    context 'when conditions are empty' do
      let(:conditions) { {} }
      it 'returns true' do
        expect(service.call).to be true
      end
    end

    context 'with single condition' do
      let(:conditions) do
        {
          "operator" => "AND",
          "groups" => [
            {
              "operator" => "OR",
              "conditions" => [
                { "attribute" => "priority", "operator" => "equals", "value" => "high" }
              ]
            }
          ]
        }
      end

      it 'returns true if matched' do
        expect(service.call).to be true
      end

      it 'returns false if not matched' do
        allow(conversation).to receive(:priority).and_return('low')
        expect(service.call).to be false
      end
    end

    context 'with multiple conditions (AND/OR logic)' do
      let(:conditions) do
        {
          "operator" => "AND",
          "groups" => [
            {
              "operator" => "OR",
              "conditions" => [
                { "attribute" => "status", "operator" => "equals", "value" => "open" },
                { "attribute" => "priority", "operator" => "equals", "value" => "urgent" }
              ]
            },
            {
              "operator" => "AND",
              "conditions" => [
                { "attribute" => "customer.email", "operator" => "contains", "value" => "@example.com" }
              ]
            }
          ]
        }
      end

      it 'returns true if logic matches' do
        expect(service.call).to be true
      end

      it 'returns false if AND condition fails' do
        allow(conversation.customers.first).to receive(:email).and_return('cust@other.com')
        expect(service.call).to be false
      end
    end

    context 'with custom fields' do
      let(:conditions) do
        {
          "groups" => [
            {
              "conditions" => [
                { "attribute" => "custom_field.custom_id", "operator" => "equals", "value" => "XYZ" }
              ]
            }
          ]
        }
      end

      it 'matches custom fields from data jsonb' do
        expect(service.call).to be true
      end
    end
  end
end

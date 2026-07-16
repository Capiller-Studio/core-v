require 'rails_helper'

RSpec.describe Automations::EventDispatcher do
  let(:account) { double('Account') }
  let(:payload) { { "id" => 123, "status" => "open" } }
  let(:service) { described_class.new(event_name: 'conversation.created', payload: payload, account: account) }

  describe '#call' do
    let(:automations_scope) { double('AutomationsScope') }
    let(:rule1) { double('Automation', id: 1, stop_processing?: false, conditions: { "groups" => [{}] }) }
    let(:rule2) { double('Automation', id: 2, stop_processing?: true, conditions: { "groups" => [{}] }) }
    let(:rule3) { double('Automation', id: 3, stop_processing?: false, conditions: { "groups" => [{}] }) }

    before do
      allow(account).to receive(:automations).and_return(automations_scope)
      stub_const('Automations::ExecutionWorker', double('ExecutionWorker'))
    end

    it 'returns if cascade depth is 3 or more' do
      service = described_class.new(event_name: 'conversation.created', payload: payload, account: account, cascade_depth: 3)
      expect(account).not_to receive(:automations)
      service.call
    end

    it 'returns if no rules match event' do
      allow(automations_scope).to receive(:event_triggers_for).with('conversation.created').and_return([])
      expect(Automations::ExecutionWorker).not_to receive(:perform_async)
      service.call
    end

    context 'with matching rules' do
      before do
        allow(automations_scope).to receive(:event_triggers_for).with('conversation.created').and_return([rule1, rule2, rule3])
        allow(Automations::ConditionEvaluator).to receive(:call).and_return(true)
      end

      it 'queues execution worker for rules and stops if stop_processing? is true' do
        expect(Automations::ExecutionWorker).to receive(:perform_async).with("Automation", 1, "Conversation", 123, "event", 0)
        expect(Automations::ExecutionWorker).to receive(:perform_async).with("Automation", 2, "Conversation", 123, "event", 0)
        
        # Rule 3 should not be executed because Rule 2 has stop_processing? = true
        expect(Automations::ExecutionWorker).not_to receive(:perform_async).with("Automation", 3, "Conversation", 123, "event", 0)
        
        service.call
      end

      it 'resolves resource_type correctly based on event_name' do
        service = described_class.new(event_name: 'message.created', payload: payload, account: account)
        
        allow(automations_scope).to receive(:event_triggers_for).with('message.created').and_return([rule1])
        
        expect(Automations::ExecutionWorker).to receive(:perform_async).with("Automation", 1, "Message", 123, "event", 0)
        
        service.call
      end
    end
    
    context 'when rule conditions do not match' do
      before do
        allow(automations_scope).to receive(:event_triggers_for).with('conversation.created').and_return([rule1])
        allow(Automations::ConditionEvaluator).to receive(:call).and_return(false)
      end

      it 'skips the rule' do
        expect(Automations::ExecutionWorker).not_to receive(:perform_async)
        service.call
      end
    end
  end
end

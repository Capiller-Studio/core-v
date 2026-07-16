require 'rails_helper'

RSpec.describe Automations::ActionExecutor do
  let(:account) { double('Account') }
  let(:resource) { double('Conversation') }
  let(:executable) { double('Executable', actions: actions) }
  let(:service) { described_class.new(executable: executable, resource: resource, account: account) }

  describe '#call' do
    context 'when actions array is empty' do
      let(:actions) { [] }
      
      it 'returns an empty array' do
        expect(service.call).to eq([])
      end
    end

    context 'with known actions' do
      let(:actions) { [{ "action" => "set_status", "params" => { "status" => "resolved" } }] }

      it 'executes the action and returns success' do
        expect(Automations::Actions::SetStatus).to receive(:call).with(
          resource: resource,
          account: account,
          params: { "status" => "resolved" }
        )

        results = service.call
        
        expect(results.length).to eq(1)
        expect(results.first).to include(
          "action" => "set_status",
          "result" => "success"
        )
      end

      it 'captures errors and returns failed result' do
        expect(Automations::Actions::SetStatus).to receive(:call).and_raise(StandardError.new('Something went wrong'))

        results = service.call
        
        expect(results.length).to eq(1)
        expect(results.first).to include(
          "action" => "set_status",
          "result" => "failed",
          "error" => "Something went wrong"
        )
      end
    end

    context 'with unknown action' do
      let(:actions) { [{ "action" => "destroy_world", "params" => {} }] }

      it 'returns failed result indicating unknown action' do
        results = service.call
        
        expect(results.length).to eq(1)
        expect(results.first).to include(
          "action" => "destroy_world",
          "result" => "failed",
          "error" => "Unknown action: destroy_world"
        )
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Automations::ActionExecutor do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:resource) { create(:conversation, account: account, inbox: inbox) }
  let(:executable) { build(:automation, account: account, actions: actions) }
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

    context 'with multiple actions (both successful and failed)' do
      let(:actions) do
        [
          { "action" => "set_status", "params" => { "status" => "resolved" } },
          { "action" => "add_label", "params" => { "label" => "vip" } },
          { "action" => "destroy_world", "params" => {} }
        ]
      end

      it 'continues execution even if some actions fail' do
        expect(Automations::Actions::SetStatus).to receive(:call)
        expect(Automations::Actions::AddLabel).to receive(:call).and_raise(StandardError.new('Label not found'))

        results = service.call
        
        expect(results.length).to eq(3)
        expect(results[0]).to include("action" => "set_status", "result" => "success")
        expect(results[1]).to include("action" => "add_label", "result" => "failed", "error" => "Label not found")
        expect(results[2]).to include("action" => "destroy_world", "result" => "failed", "error" => "Unknown action: destroy_world")
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

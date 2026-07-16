require 'rails_helper'

RSpec.describe Automations::ActionsValidator do
  let(:service) { described_class.new(actions: actions) }

  describe '#valid?' do
    context 'when actions is not an array' do
      let(:actions) { "not an array" }
      it 'returns false with error' do
        expect(service.valid?).to be false
        expect(service.errors).to include("actions must be an array")
      end
    end

    context 'when actions is empty' do
      let(:actions) { [] }
      it 'returns false with error' do
        expect(service.valid?).to be false
        expect(service.errors).to include("at least one action is required")
      end
    end

    context 'with invalid action structure' do
      let(:actions) { ["not a hash"] }
      it 'returns false with error' do
        expect(service.valid?).to be false
        expect(service.errors).to include("actions[0] must be a JSON object")
      end
    end

    context 'with unknown action' do
      let(:actions) { [{ "action" => "do_magic" }] }
      it 'returns false with error' do
        expect(service.valid?).to be false
        expect(service.errors).to include("actions[0].action 'do_magic' is not valid")
      end
    end

    context 'with valid action missing params' do
      let(:actions) { [{ "action" => "assign_agent" }] }
      it 'returns false with missing param error' do
        expect(service.valid?).to be false
        expect(service.errors).to include("actions[0].params.agent_id is required")
      end
    end

    context 'with invalid param values' do
      let(:actions) { [{ "action" => "set_status", "params" => { "status" => "invalid_status" } }] }
      it 'returns false with invalid param error' do
        expect(service.valid?).to be false
        expect(service.errors).to include("actions[0].params.status must be active, closed, snoozed, or resolved")
      end
    end

    context 'with webhook ssrf validation' do
      it 'blocks localhost' do
        validator = described_class.new(actions: [{ "action" => "trigger_webhook", "params" => { "url" => "http://localhost:3000" } }])
        expect(validator.valid?).to be false
        expect(validator.errors.first).to match(/cannot target internal or private network addresses/)
      end

      it 'allows valid https urls' do
        validator = described_class.new(actions: [{ "action" => "trigger_webhook", "params" => { "url" => "https://example.com/webhook" } }])
        expect(validator.valid?).to be true
      end
    end

    context 'with valid actions' do
      let(:actions) do
        [
          { "action" => "assign_agent", "params" => { "agent_id" => 1 } },
          { "action" => "set_priority", "params" => { "priority" => "urgent" } }
        ]
      end

      it 'returns true' do
        expect(service.valid?).to be true
      end
    end
  end
end

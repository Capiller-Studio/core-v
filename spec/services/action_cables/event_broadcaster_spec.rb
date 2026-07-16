require 'rails_helper'

RSpec.describe ActionCables::EventBroadcaster do
  include ActiveSupport::Testing::TimeHelpers
  
  let(:data) { { id: 1, name: 'Test Object' } }
  let(:event) { 'test.created' }
  let(:connection_tokens) { ['token_1', 'token_2'] }
  let(:service) { described_class.new(data: data, event: event, connection_tokens: connection_tokens) }

  describe '#initialize' do
    it 'sets the attributes correctly' do
      freeze_time do
        expect(service.data).to eq(data)
        expect(service.event).to eq(event)
        expect(service.connection_tokens).to eq(connection_tokens)
        expect(service.timestamp).to eq(Time.now.to_i)
      end
    end
  end

  describe '#call' do
    context 'when successful' do
      before do
        allow(ActionCable.server).to receive(:broadcast)
      end

      it 'configures the body correctly and broadcasts to all tokens' do
        freeze_time do
          expected_body = {
            event: event,
            timestamp: Time.now.to_i,
            object: data
          }

          result = service.call

          expect(result).to be true
          expect(service.body).to eq(expected_body)
          expect(ActionCable.server).to have_received(:broadcast).with('token_1', expected_body)
          expect(ActionCable.server).to have_received(:broadcast).with('token_2', expected_body)
        end
      end
    end

    context 'when connection_tokens are blank' do
      let(:connection_tokens) { [] }

      it 'returns true without broadcasting' do
        allow(ActionCable.server).to receive(:broadcast)
        
        result = service.call
        
        expect(result).to be true
        expect(ActionCable.server).not_to have_received(:broadcast)
      end
    end

    context 'when connection_tokens contain blank values' do
      let(:connection_tokens) { ['token_1', nil, '', 'token_2'] }

      it 'skips the blank values and broadcasts to valid tokens' do
        allow(ActionCable.server).to receive(:broadcast)
        
        service.call
        
        expect(ActionCable.server).to have_received(:broadcast).twice
        expect(ActionCable.server).to have_received(:broadcast).with('token_1', anything)
        expect(ActionCable.server).to have_received(:broadcast).with('token_2', anything)
      end
    end

    context 'when an error occurs' do
      before do
        allow(ActionCable.server).to receive(:broadcast).and_raise(StandardError, 'Broadcast failed')
        allow(Rails.logger).to receive(:error)
      end

      it 'rescues the error, logs it, and returns false' do
        result = service.call
        
        expect(result).to be false
        expect(Rails.logger).to have_received(:error).with('EventBroadcaster failed: Broadcast failed')
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Automations::Actions::SetPriority do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, priority: :low) }

  describe '#call' do
    context 'when priority is invalid' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { priority: 'invalid' }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('Invalid priority: invalid')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { priority: 'high' }) }

      it 'updates the conversation priority' do
        expect { service.call }.to change { conversation.reload.priority }.from('low').to('high')
      end
    end
  end
end

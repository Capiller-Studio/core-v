require 'rails_helper'

RSpec.describe Automations::Actions::SetStatus do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :active) }

  describe '#call' do
    context 'when status is invalid' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { status: 'invalid' }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('Invalid status: invalid')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { status: 'closed' }) }

      it 'updates the conversation status' do
        expect { service.call }.to change { conversation.reload.status }.from('active').to('closed')
      end
    end
  end
end

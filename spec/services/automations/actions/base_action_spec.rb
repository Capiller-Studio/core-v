require 'rails_helper'

RSpec.describe Automations::Actions::BaseAction do
  let(:account) { double('Account') }
  let(:resource) { double('Resource') }
  let(:params) { { some: 'param' } }
  let(:service) { described_class.new(resource: resource, account: account, params: params) }

  describe '#initialize' do
    it 'sets resource, account, and indifferent access params' do
      expect(service.resource).to eq(resource)
      expect(service.account).to eq(account)
      expect(service.params[:some]).to eq('param')
      expect(service.params['some']).to eq('param')
    end
  end

  describe '#call' do
    it 'raises NotImplementedError' do
      expect { service.call }.to raise_error(NotImplementedError, 'Subclasses must implement #call')
    end
  end

  describe '#require_conversation!' do
    context 'when resource is a Conversation' do
      let(:resource) { build_stubbed(:conversation) }

      it 'does not raise an error' do
        expect { service.send(:require_conversation!) }.not_to raise_error
      end
    end

    context 'when resource is not a Conversation' do
      let(:resource) { double('Customer') }

      it 'raises an error' do
        expect { service.send(:require_conversation!) }.to raise_error("Resource must be a Conversation, got RSpec::Mocks::Double")
      end
    end
  end
end

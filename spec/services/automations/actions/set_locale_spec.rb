require 'rails_helper'

RSpec.describe Automations::Actions::SetLocale do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, locale: 'en') }

  describe '#call' do
    context 'when locale is missing' do
      let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

      it 'raises an error' do
        expect { service.call }.to raise_error('locale is required')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { locale: 'es' }) }

      it 'updates the conversation locale' do
        expect { service.call }.to change { conversation.reload.locale }.from('en').to('es')
      end
    end
  end
end

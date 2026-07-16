require 'rails_helper'

RSpec.describe Automations::Actions::Resolve do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :active) }

  describe '#call' do
    let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

    it 'updates the conversation status to resolved' do
      expect { service.call }.to change { conversation.reload.status }.from('active').to('resolved')
    end
  end
end

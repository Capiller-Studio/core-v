require 'rails_helper'

RSpec.describe Automations::Actions::MuteConversation do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#call' do
    let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

    it 'sets muted to true in configurations' do
      expect { service.call }.to change { conversation.reload.configurations["muted"] }.from(nil).to(true)
    end
  end
end

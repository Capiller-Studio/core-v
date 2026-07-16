require 'rails_helper'

RSpec.describe Automations::Actions::Unassign do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }
  let(:conversation) { create(:conversation, account: account, assignee: agent) }

  describe '#call' do
    let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

    it 'unassigns the conversation' do
      expect(conversation).to receive(:unassign!)
      service.call
    end
  end
end

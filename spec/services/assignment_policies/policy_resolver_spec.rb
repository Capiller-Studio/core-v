require 'rails_helper'

RSpec.describe AssignmentPolicies::PolicyResolver do
  let(:inbox) { double('Inbox') }
  let(:conversation) { double('Conversation', inbox: inbox) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#call' do
    let(:policy) { double('AssignmentPolicy') }
    let(:for_inbox_scope) { double('ForInboxScope') }

    before do
      stub_const('AssignmentPolicy', double('AssignmentPolicyClass'))
      allow(AssignmentPolicy).to receive(:for_inbox).with(inbox).and_return(for_inbox_scope)
    end

    it 'returns the first matching policy for the inbox' do
      allow(for_inbox_scope).to receive(:first).and_return(policy)
      
      expect(service.call).to eq(policy)
    end

    it 'returns nil if no policy matches' do
      allow(for_inbox_scope).to receive(:first).and_return(nil)
      
      expect(service.call).to be_nil
    end
  end
end

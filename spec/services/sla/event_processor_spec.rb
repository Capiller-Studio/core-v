require 'rails_helper'

RSpec.describe Sla::EventProcessor do
  let(:account) { double('Account') }
  let(:conversation) { double('Conversation', account: account, inbox_id: 1) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#call' do
    context 'when conversation is resolved or closed' do
      let(:sla1) { double('ConversationSla') }
      let(:sla2) { double('ConversationSla') }
      let(:active_slas) { [sla1, sla2] }
      let(:conversation_slas) { double('ConversationSlas', active: active_slas) }

      before do
        allow(conversation).to receive(:resolved?).and_return(true)
        allow(conversation).to receive(:closed?).and_return(false)
        allow(conversation).to receive(:conversation_slas).and_return(conversation_slas)
      end

      it 'marks active slas as successful' do
        expect(sla1).to receive(:mark_as_successful!)
        expect(sla2).to receive(:mark_as_successful!)
        
        service.call
      end
    end

    context 'when conversation is active' do
      let(:sla_policy) { double('SlaPolicy') }
      let(:policies_scope) { double('PoliciesScope') }
      let(:joins_scope) { double('JoinsScope') }
      let(:where_scope) { double('WhereScope') }
      let(:conversation_sla) { double('ConversationSla', failed?: false) }

      before do
        allow(conversation).to receive(:resolved?).and_return(false)
        allow(conversation).to receive(:closed?).and_return(false)
        
        allow(account).to receive(:sla_policies).and_return(policies_scope)
        allow(policies_scope).to receive(:joins).with(:sla_inboxes).and_return(joins_scope)
        allow(joins_scope).to receive(:where).with(sla_inboxes: { inbox_id: 1 }).and_return(where_scope)
        
        stub_const('ConversationSla', double('ConversationSlaClass'))
      end

      it 'does nothing if no policy is found' do
        allow(where_scope).to receive(:first).and_return(nil)
        
        expect(ConversationSla).not_to receive(:find_or_initialize_by)
        service.call
      end

      it 'creates or updates SLA and recalculates targets' do
        allow(where_scope).to receive(:first).and_return(sla_policy)
        
        expect(ConversationSla).to receive(:find_or_initialize_by).with(
          conversation: conversation,
          sla_policy: sla_policy,
          account: account
        ).and_return(conversation_sla)
        
        expect(conversation_sla).to receive(:status=).with(:pending)
        expect(conversation_sla).to receive(:save!)
        expect(conversation_sla).to receive(:recalculate_targets!)
        
        service.call
      end

      it 'does not set status to pending if already failed' do
        allow(where_scope).to receive(:first).and_return(sla_policy)
        failed_sla = double('ConversationSla', failed?: true)
        
        allow(ConversationSla).to receive(:find_or_initialize_by).and_return(failed_sla)
        
        expect(failed_sla).not_to receive(:status=)
        expect(failed_sla).to receive(:save!)
        expect(failed_sla).to receive(:recalculate_targets!)
        
        service.call
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sla::EventProcessor do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#call' do
    context 'when conversation is resolved or closed' do
      let!(:sla_policy) { create(:sla_policy, account: account, initial_response_time_limit: 60, resolution_time_limit: 180) }
      let!(:sla) { create(:conversation_sla, account: account, conversation: conversation, sla_policy: sla_policy, status: :pending) }

      it 'marks SLA as successful if not breached' do
        conversation.update_columns(status: Conversation.statuses[:resolved], status_changed_at: 10.seconds.ago)
        sla.update_columns(target_resolution_at: 1.minute.from_now)

        service.call

        expect(sla.reload.status).to eq('successful')
      end

      it 'marks SLA as breached if resolution deadline was exceeded' do
        conversation.update_columns(status: Conversation.statuses[:resolved], status_changed_at: 5.minutes.ago)
        sla.update_columns(target_resolution_at: 10.minutes.ago)

        service.call

        expect(sla.reload.status).to eq('failed')
      end
    end

    context 'when conversation is active' do
      context 'with no applicable policies' do
        it 'does not create any conversation SLAs' do
          expect { service.call }.not_to change(ConversationSla, :count)
        end
      end

      context 'with inbox-specific policy' do
        let!(:sla_policy) { create(:sla_policy, account: account, initial_response_time_limit: 60) }
        let!(:sla_inbox) { create(:sla_inbox, sla_policy: sla_policy, inbox: inbox) }

        it 'creates a conversation SLA and calculates targets' do
          expect { service.call }.to change(ConversationSla, :count).by(1)

          sla = conversation.conversation_slas.last
          expect(sla.sla_policy).to eq(sla_policy)
          expect(sla.status).to eq('pending')
          expect(sla.target_first_response_at).to be_present
        end
      end

      context 'with global policy' do
        let!(:global_policy) { create(:sla_policy, account: account, initial_response_time_limit: 120) }

        it 'applies global policy when no inbox-specific policy exists' do
          expect { service.call }.to change(ConversationSla, :count).by(1)

          sla = conversation.conversation_slas.last
          expect(sla.sla_policy).to eq(global_policy)
          expect(sla.status).to eq('pending')
        end
      end

      context 'when existing SLA has already breached' do
        let!(:sla_policy) { create(:sla_policy, account: account) }
        let!(:sla_inbox) { create(:sla_inbox, sla_policy: sla_policy, inbox: inbox) }
        let!(:breached_sla) do
          create(:conversation_sla, account: account, conversation: conversation, sla_policy: sla_policy, status: :failed)
        end

        it 'does not revert breached SLA back to pending' do
          service.call

          expect(breached_sla.reload.status).to eq('failed')
        end
      end
    end
  end
end

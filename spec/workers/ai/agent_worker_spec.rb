# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::AgentWorker, type: :worker do
  let(:account) { create(:account) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:ai_agent) { create(:ai_agent, account: account, portal: portal, fallback_message: 'Connecting to human...') }
  let(:inbox) { create(:inbox, account: account, ai_agent: ai_agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, ai_status: :ai_active) }
  let(:customer) { create(:customer, account: account) }
  let!(:member) { create(:conversation_member, conversation: conversation, member: customer, account: account) }
  let!(:customer_inbox) { create(:customer_inbox, customer: customer, inbox: inbox) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, sender: customer, content: 'How do I reset my password?') }

  before do
    conversation.update_column(:ai_status, 1) # ai_active
  end

  describe '#perform' do
    context 'with debounced multi-message bursts' do
      it 'bundles all buffered messages into a single HelpCenterBot query and broadcasts typing indicators' do
        msg2 = create(:message, account: account, conversation: conversation, inbox: inbox, sender: customer, content: 'I forgot it yesterday')
        msg3 = create(:message, account: account, conversation: conversation, inbox: inbox, sender: customer, content: 'Can you help?')

        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message, msg2, msg3])
        allow(Ai::MessageDebouncer).to receive(:ready_to_process?).and_return(true)

        expect(ActionCable.server).to receive(:broadcast).with(
          customer_inbox.connection_token,
          hash_including(event: 'typing', status: 'start')
        )
        expect(ActionCable.server).to receive(:broadcast).with(
          customer_inbox.connection_token,
          hash_including(event: 'typing', status: 'stop')
        )

        expect(Ai::HelpCenterBot).to receive(:call).with(
          hash_including(
            query: "How do I reset my password?\nI forgot it yesterday\nCan you help?"
          )
        ).and_return('Here is how to reset your password.')

        allow(Messages::DeliveryWorker).to receive(:perform_async)

        expect {
          described_class.new.perform(account.id, conversation.id, ai_agent.id, 'token_123')
        }.to change { conversation.messages.count }.by(1)

        ai_msg = conversation.messages.where(sender: ai_agent).last
        expect(ai_msg).to be_present
        expect(ai_msg.content).to eq('Here is how to reset your password.')
      end

      it 'broadcasts typing indicators to all conversation participants including agents' do
        agent_user = create(:user)
        create(:conversation_member, conversation: conversation, member: agent_user, account: account)

        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message])
        allow(Ai::MessageDebouncer).to receive(:ready_to_process?).and_return(true)
        allow(Ai::HelpCenterBot).to receive(:call).and_return('Help text')
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        expect(ActionCable.server).to receive(:broadcast).with(customer_inbox.connection_token, hash_including(event: 'typing', status: 'start'))
        expect(ActionCable.server).to receive(:broadcast).with(agent_user.connection_token, hash_including(event: 'typing', status: 'start'))
        expect(ActionCable.server).to receive(:broadcast).with(customer_inbox.connection_token, hash_including(event: 'typing', status: 'stop'))
        expect(ActionCable.server).to receive(:broadcast).with(agent_user.connection_token, hash_including(event: 'typing', status: 'stop'))

        described_class.new.perform(account.id, conversation.id, ai_agent.id)
      end

      it 'aborts early if worker has been superseded by a newer debounce token' do
        allow(Ai::MessageDebouncer).to receive(:ready_to_process?).and_return(false)

        expect(Ai::HelpCenterBot).not_to receive(:call)
        expect(conversation.messages).not_to receive(:create!)

        described_class.new.perform(account.id, conversation.id, ai_agent.id, 'stale_token')
      end

      it 'aborts early if conversation is no longer ai_active' do
        conversation.update_column(:ai_status, 2) # handed off

        expect(Ai::MessageDebouncer).not_to receive(:drain_messages)
        expect(Ai::HelpCenterBot).not_to receive(:call)

        described_class.new.perform(account.id, conversation.id, ai_agent.id)
      end

      it 'aborts early if ai_agent is no longer active' do
        ai_agent.update!(status: :inactive)

        expect(Ai::MessageDebouncer).not_to receive(:drain_messages)
        expect(Ai::HelpCenterBot).not_to receive(:call)

        described_class.new.perform(account.id, conversation.id, ai_agent.id)
      end
    end

    context 'when help center bot returns a response' do
      it 'creates an AI message, formats markdown, and queues delivery worker' do
        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message])
        allow(Ai::HelpCenterBot).to receive(:call).and_return('Here is how you reset your password: click [here](https://example.com)')
        allow(Channels::MessageFormatter).to receive(:parse_ai_markdown_to_html).and_return('<p>Here is how you reset your password</p>')

        expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String))

        expect {
          described_class.new.perform(account.id, conversation.id, ai_agent.id)
        }.to change { conversation.messages.count }.by(1)

        ai_msg = conversation.messages.where(sender: ai_agent).last
        expect(ai_msg).to be_present
        expect(ai_msg.content).to eq('<p>Here is how you reset your password</p>')
        expect(ai_msg.sender).to eq(ai_agent)
      end
    end

    context 'when AI returns fallback / handoff' do
      it 'triggers human handoff and marks conversation ai_handed_off' do
        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message])
        allow(Ai::HelpCenterBot).to receive(:call).and_return('Connecting to human...')
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        described_class.new.perform(account.id, conversation.id, ai_agent.id)

        conversation.reload
        expect(conversation.ai_status).to eq('ai_handed_off')
      end

      it 'localizes fallback message according to conversation.locale' do
        ai_agent.update!(fallback_message: nil)
        conversation.update!(locale: 'es')

        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message])
        allow(Ai::HelpCenterBot).to receive(:call).and_return(
          I18n.t('ai.widget_bot.default_fallback', locale: :es)
        )
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        described_class.new.perform(account.id, conversation.id, ai_agent.id)

        ai_msg = conversation.messages.where(sender: ai_agent).last
        expect(ai_msg.content).to eq(I18n.t('ai.widget_bot.default_fallback', locale: :es))
      end
    end

    context 'when AiInsufficientBalanceError is raised' do
      it 'rescues, creates fallback message, and triggers human handoff with note' do
        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message])
        stub_const('AiInsufficientBalanceError', Class.new(StandardError))
        allow(Ai::HelpCenterBot).to receive(:call).and_raise(AiInsufficientBalanceError.new('No credits'))
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        expect {
          described_class.new.perform(account.id, conversation.id, ai_agent.id)
        }.not_to raise_error

        conversation.reload
        expect(conversation.ai_status).to eq('ai_handed_off')
        note = conversation.messages.where(content_type: :activity).last
        expect(note.content).to include('insufficient AI Credits')
      end
    end

    context 'when Faraday or OpenAI API error is raised' do
      it 'rescues, sends fallback, and creates api error note' do
        allow(Ai::MessageDebouncer).to receive(:drain_messages).and_return([message])
        allow(Ai::HelpCenterBot).to receive(:call).and_raise(Faraday::ConnectionFailed.new('Connection refused'))
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        expect {
          described_class.new.perform(account.id, conversation.id, ai_agent.id)
        }.not_to raise_error

        conversation.reload
        expect(conversation.ai_status).to eq('ai_handed_off')
        note = conversation.messages.where(content_type: :activity).last
        expect(note.content).to include('temporary API error')
      end
    end
  end

  describe 'sidekiq_retries_exhausted' do
    it 'forces human handoff and writes crash note to conversation' do
      msg = {
        'args' => [account.id, conversation.id, ai_agent.id]
      }

      described_class.sidekiq_retries_exhausted_block.call(msg, StandardError.new('Fatal crash'))

      conversation.reload
      expect(conversation.ai_status).to eq('ai_handed_off')
      crash_note = conversation.messages.where(content_type: :activity, visibility: :personal).last
      expect(crash_note).to be_present
      expect(crash_note.content).to include('repeatedly failed to process')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SLA Policy Lifecycle and Breach Processing End-To-End', type: :service do
  let(:account) { create(:account) }
  let(:agent) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: agent, owner: true) }
  let(:inbox) { create(:inbox, account: account, name: 'Tier 1 Support') }
  let!(:inbox_user) { create(:inbox_user, inbox: inbox, user: agent) }

  let(:sla_policy) do
    create(:sla_policy,
      account: account,
      name: 'High Priority SLA',
      initial_response_time_limit: 900,  # 15 mins
      resolution_time_limit: 7200,       # 2 hours
      during_working_hours: false
    )
  end
  let!(:sla_inbox) { create(:sla_inbox, sla_policy: sla_policy, inbox: inbox) }

  describe 'Full SLA Lifecycle: Assignment -> First Response -> Resolution Achieved' do
    let(:conversation) do
      create(:conversation,
        account: account,
        inbox: inbox,
        status: :active,
        assignee: agent,
        created_at: 10.minutes.ago
      )
    end

    it 'attaches SLA targets, respects first response, and achieves resolution successfully' do
      # 1. New conversation arrives -> EventProcessor attaches SLA
      Sla::EventProcessor.new(conversation: conversation).call

      sla = conversation.conversation_slas.last
      expect(sla).to be_present
      expect(sla.sla_policy).to eq(sla_policy)
      expect(sla.status).to eq('pending')
      expect(sla.target_first_response_at).to be_within(5.seconds).of(conversation.created_at + 15.minutes)
      expect(sla.target_resolution_at).to be_within(5.seconds).of(conversation.created_at + 2.hours)

      # 2. Agent responds within 15 minutes (at 5 minutes in)
      conversation.update!(first_respond_at: conversation.created_at + 5.minutes)

      # SlaCheckWorker runs: should still be on track (pending)
      SlaCheckWorker.new.perform
      expect(sla.reload.status).to eq('pending')

      # 3. Conversation is resolved 1 hour later (well before 2 hour deadline)
      conversation.update!(status: :resolved, status_changed_at: conversation.created_at + 1.hour)
      Sla::EventProcessor.new(conversation: conversation).call

      expect(sla.reload.status).to eq('successful')
    end
  end

  describe 'SLA Breach Detection and Automated Worker Execution' do
    let(:conversation) do
      create(:conversation,
        account: account,
        inbox: inbox,
        status: :active,
        assignee: agent,
        created_at: 30.minutes.ago
      )
    end

    it 'detects first response breach when deadline passes without agent reply and notifies assignee' do
      # SLA created with target 15 mins from created_at (which is 15 mins in the past)
      sla = create(:conversation_sla,
        account: account,
        conversation: conversation,
        sla_policy: sla_policy,
        status: :pending,
        target_first_response_at: conversation.created_at + 15.minutes,
        target_resolution_at: conversation.created_at + 2.hours
      )

      expect {
        SlaCheckWorker.new.perform
      }.to change(Notification, :count).by_at_least(1)

      expect(sla.reload.status).to eq('failed')
    end

    it 'detects resolution breach when ticket exceeds resolution deadline' do
      sla = create(:conversation_sla,
        account: account,
        conversation: conversation,
        sla_policy: sla_policy,
        status: :pending,
        target_first_response_at: conversation.created_at + 15.minutes,
        target_resolution_at: 5.minutes.ago
      )

      # Agent had responded in time, but failed to resolve
      conversation.update!(first_respond_at: conversation.created_at + 10.minutes)

      SlaCheckWorker.new.perform
      expect(sla.reload.status).to eq('failed')
    end
  end

  describe 'SLA Policy Resolution Precedence' do
    let(:other_inbox) { create(:inbox, account: account, name: 'General Inquiries') }
    let!(:global_policy) do
      create(:sla_policy,
        account: account,
        name: 'Default Global SLA',
        initial_response_time_limit: 3600 # 1 hour
      )
    end

    it 'prefers inbox-specific policy over global fallback policy' do
      conv_in_tiered_inbox = create(:conversation, account: account, inbox: inbox, status: :active)
      Sla::EventProcessor.new(conversation: conv_in_tiered_inbox).call

      sla = conv_in_tiered_inbox.conversation_slas.last
      expect(sla.sla_policy).to eq(sla_policy)
      expect(sla.sla_policy).not_to eq(global_policy)
    end

    it 'falls back to global policy when no inbox-specific SLA policy is attached' do
      conv_in_general_inbox = create(:conversation, account: account, inbox: other_inbox, status: :active)
      Sla::EventProcessor.new(conversation: conv_in_general_inbox).call

      sla = conv_in_general_inbox.conversation_slas.last
      expect(sla.sla_policy).to eq(global_policy)
    end
  end
end

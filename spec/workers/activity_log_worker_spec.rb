# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityLogWorker, type: :worker do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    let(:params) do
      {
        trackable_type: 'Conversation',
        trackable_id: conversation.id,
        actor_type: 'User',
        actor_id: user.id,
        event_type: 'assigned',
        changes: { 'assignee_id' => [nil, user.id] },
        snapshot: { 'id' => conversation.id, 'status' => 'open' },
        metadata: { 'source' => 'web' }
      }
    end

    it 'creates an activity record with the supplied snapshot and parameters' do
      expect {
        described_class.new.perform(account.id, params)
      }.to change { Activity.where(account_id: account.id).count }.by(1)

      activity = Activity.where(account_id: account.id).last
      expect(activity.account_id).to eq(account.id)
      expect(activity.trackable_type).to eq('Conversation')
      expect(activity.trackable_id).to eq(conversation.id)
      expect(activity.actor_type).to eq('User')
      expect(activity.actor_id).to eq(user.id)
      expect(activity.event_key).to eq('conversation.assigned')
      expect(activity.object_changes).to eq({ 'assignee_id' => [nil, user.id] })
      expect(activity.object_snapshot).to eq({ 'id' => conversation.id, 'status' => 'open' })
      expect(activity.metadata).to eq({ 'source' => 'web' })
    end

    it 'raises error if account is not found' do
      expect {
        described_class.new.perform(999_999, params)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

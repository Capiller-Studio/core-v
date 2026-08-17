# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Activity, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:actor).optional }
    it { is_expected.to belong_to(:trackable) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:event_key) }
  end

  describe 'scopes and methods' do
    let!(:activity) do
      account.with_shard do
        create(
          :activity,
          account: account,
          actor: user,
          trackable: conversation,
          event_key: 'conversation.status_changed',
          object_changes: { 'status' => ['open', 'resolved'] },
          object_snapshot: { 'status' => 'resolved', 'title' => 'Billing Issue' }
        )
      end
    end

    it 'queries by changed attribute' do
      account.with_shard do
        expect(described_class.with_changed_attribute(:status)).to include(activity)
        expect(described_class.with_changed_attribute(:nonexistent)).not_to include(activity)
      end
    end

    it 'queries by attribute snapshot value' do
      account.with_shard do
        expect(described_class.with_attribute_value(:status, 'resolved')).to include(activity)
        expect(described_class.with_attribute_value(:status, 'pending')).not_to include(activity)
      end
    end

    it 'formats event_data extracting latest values' do
      expect(activity.event_data).to eq({ 'status' => 'resolved' })
    end

    it 'provides a translated description fallback' do
      expect(activity.translated_description).to be_present
    end

    it 'broadcasts activity via EventBroadcastWorker' do
      expect(EventBroadcastWorker).to receive(:perform_async)
      account.with_shard do
        create(:activity, account: account, actor: user, trackable: conversation, event_key: 'custom_event')
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trackable, type: :model do
  let(:account) { create(:account) }

  describe '#snapshot_payload and #changes_payload' do
    it 'captures snapshot of record attributes' do
      conversation = create(:conversation, account: account, title: 'Initial Title')

      snapshot = conversation.snapshot_payload
      expect(snapshot['title']).to eq('Initial Title')
      expect(snapshot['account_id']).to eq(account.id)
    end
  end

  describe 'activity recording triggers' do
    it 'calls Activities::Recorder on update' do
      conversation = create(:conversation, account: account, title: 'Old Title')

      expect(Activities::Recorder).to receive(:call).with(
        hash_including(trackable: conversation, event_type: :update)
      )

      conversation.update!(title: 'New Title')
    end

    it 'calls Activities::Recorder on destroy' do
      conversation = create(:conversation, account: account)

      expect(Activities::Recorder).to receive(:call).with(
        hash_including(trackable: conversation, event_type: :destroy)
      )

      conversation.destroy!
    end
  end
end

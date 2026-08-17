# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assignable, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:team) { create(:team, account: account) }

  before do
    allow(Activities::Recorder).to receive(:call)
  end

  describe '#assign! and #unassign!' do
    it 'assigns a user, creates conversation member, and sends notification' do
      expect {
        conversation.assign!(user)
      }.to change { Notification.count }.by(1)

      expect(conversation.assignee).to eq(user)
      expect(conversation.assigned?).to be(true)
      expect(conversation.conversation_members.find_by(member: user)).to be_present
      expect(Activities::Recorder).to have_received(:call).with(
        hash_including(event_type: :conversation_assigned)
      )
    end

    it 'unassigns a user and records activity' do
      conversation.assign!(user)

      conversation.unassign!
      expect(conversation.assignee).to be_nil
      expect(conversation.assigned?).to be(false)
      expect(Activities::Recorder).to have_received(:call).with(
        hash_including(event_type: :conversation_unassigned)
      )
    end
  end

  describe '#assign_team! and #unassign_team!' do
    it 'assigns a team and records activity' do
      conversation.assign_team!(team)

      expect(conversation.team).to eq(team)
      expect(conversation.team_assigned?).to be(true)
      expect(Activities::Recorder).to have_received(:call).with(
        hash_including(event_type: :team_assigned)
      )
    end

    it 'unassigns a team' do
      conversation.assign_team!(team)
      conversation.unassign_team!

      expect(conversation.team).to be_nil
      expect(conversation.team_assigned?).to be(false)
      expect(Activities::Recorder).to have_received(:call).with(
        hash_including(event_type: :team_unassigned)
      )
    end
  end
end

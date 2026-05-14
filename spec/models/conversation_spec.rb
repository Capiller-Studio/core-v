require 'rails_helper'

RSpec.describe Conversation, type: :model do
  subject(:conversation) { build(:conversation) }

  describe 'Associations' do
    it { expect(conversation).to belong_to(:account) }
    it { expect(conversation).to belong_to(:inbox) }
    it { expect(conversation).to belong_to(:team).optional }
    it { expect(conversation).to belong_to(:campaign).optional }
    it { expect(conversation).to have_many(:conversation_members).dependent(:destroy) }
    it { expect(conversation).to have_many(:messages).dependent(:destroy) }
    it { expect(conversation).to have_many(:customers).through(:conversation_members) }
    it { expect(conversation).to have_many(:users).through(:conversation_members) }
  end

  describe 'Scopes' do
    let!(:account) { create(:account) }
    let!(:team) { create(:team, account: account) }
    let!(:conv_with_team) { create(:conversation, account: account, team: team) }
    let!(:conv_without_team) { create(:conversation, account: account) }

    describe '.for_team' do
      it 'returns conversations assigned to a specific team' do
        expect(Conversation.for_team(team)).to include(conv_with_team)
        expect(Conversation.for_team(team)).not_to include(conv_without_team)
      end
    end

    describe '.unassigned_team' do
      it 'returns conversations not assigned to any team' do
        expect(Conversation.unassigned_team).to include(conv_without_team)
        expect(Conversation.unassigned_team).not_to include(conv_with_team)
      end
    end
  end


  describe 'Enums' do
    it { expect(conversation).to define_enum_for(:status).with_values(active: 0, closed: 1, snoozed: 2, resolved: 3) }
    it { expect(conversation).to define_enum_for(:priority).with_values(low: 0, medium: 1, high: 2, urgent: 3) }

    it { expect(conversation).to define_enum_for(:source).with_values(
      email: 0, facebook_message: 1, whatsapp: 2, instagram_direct_message: 3,
      api: 4, web_widget: 5, sms: 6, telegram: 7, help_center: 8
    ).with_suffix(:source) }
  end

  describe 'Callbacks' do
    it 'updates last_activity_at when status changes' do
      conversation = create(:conversation)
      Timecop.freeze(1.hour.from_now) do
        expect {
          conversation.update!(status: :closed)
        }.to change { conversation.last_activity_at }
      end
    end
  end

  describe '#update_last_activity' do
    it 'updates last_activity_at' do
      conversation = create(:conversation)
      expect {
        conversation.update_last_activity
      }.to change { conversation.last_activity_at }
    end
  end

  describe 'Assignable' do
    let(:account) { create(:account) }
    let(:team) { create(:team, account: account) }
    let(:user) { create(:user) }
    let(:conversation) { create(:conversation, account: account) }

    before do
      create(:account_user, account: account, user: user)
    end

    describe '#assign_team!' do
      it 'assigns a team to the conversation' do
        conversation.assign_team!(team)
        expect(conversation.team).to eq(team)
      end

      it 'does not update if the team is the same' do
        conversation.update!(team: team)
        expect { conversation.assign_team!(team) }.not_to change { conversation.updated_at }
      end
    end

    describe '#unassign_team!' do
      it 'removes the team assignment' do
        conversation.update!(team: team)
        conversation.unassign_team!
        expect(conversation.team_id).to be_nil
      end
    end

    describe '#team_assigned?' do
      it 'returns true if a team is assigned' do
        conversation.team = team
        expect(conversation.team_assigned?).to be true
      end

      it 'returns false if no team is assigned' do
        expect(conversation.team_assigned?).to be false
      end
    end

    describe '#assign!' do
      it 'assigns a user to the conversation' do
        conversation.assign!(user)
        expect(conversation.assignee).to eq(user)
      end

      it 'replaces existing assignee' do
        other_user = create(:user)
        create(:account_user, account: account, user: other_user)
        conversation.assign!(user)
        conversation.assign!(other_user)
        expect(conversation.assignee).to eq(other_user)
        expect(conversation.conversation_members.assignees.count).to eq(1)
      end
    end
  end
end

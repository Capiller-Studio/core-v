require 'rails_helper'

RSpec.describe Conversation, type: :model do
  subject(:conversation) { build(:conversation) }

  describe 'Associations' do
    it { expect(conversation).to belong_to(:account) }
    it { expect(conversation).to belong_to(:inbox) }
    it { expect(conversation).to belong_to(:team).optional }
    it { expect(conversation).to have_many(:conversation_members).dependent(:destroy) }
    it { expect(conversation).to have_many(:messages).dependent(:destroy) }
    it { expect(conversation).to have_many(:customers).through(:conversation_members) }
    it { expect(conversation).to have_many(:users).through(:conversation_members) }
    it { expect(conversation).to belong_to(:assignee).class_name('User').optional }
    it { expect(conversation).to belong_to(:outbound_channel).optional }
    it { expect(conversation).to have_many(:applied_labels).dependent(:destroy) }
    it { expect(conversation).to have_many(:labels).through(:applied_labels) }
    it { expect(conversation).to have_many(:customer_inboxes).through(:customers) }
    it { expect(conversation).to have_many(:csat_survey_responses).class_name('Csat::SurveyResponse').dependent(:destroy) }
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

    it { expect(conversation).to define_enum_for(:ai_status).with_values(ai_inactive: 0, ai_active: 1, ai_handed_off: 2) }
  end

  describe 'Callbacks' do
    let(:account) { create(:account) }
    let(:conversation) { build(:conversation, account: account) }

    it 'broadcasts creation on create' do
      allow(conversation).to receive(:broadcast_conversation_creation)
      conversation.save!
      expect(conversation).to have_received(:broadcast_conversation_creation)
    end

    it 'updates last_activity_at when status changes' do
      conversation.save!
      Timecop.freeze(1.hour.from_now) do
        expect {
          conversation.update!(status: :closed)
        }.to change { conversation.last_activity_at }
      end
    end

    it 'calls process_sla and dispatch_csat when status changes' do
      conversation.save!
      allow(conversation).to receive(:process_sla)
      allow(conversation).to receive(:dispatch_csat)
      allow(conversation).to receive(:record_status_change)
      
      conversation.update!(status: :resolved)
      
      expect(conversation).to have_received(:process_sla)
      expect(conversation).to have_received(:dispatch_csat)
      expect(conversation).to have_received(:record_status_change)
    end

    it 'broadcasts update on update' do
      conversation.save!
      allow(conversation).to receive(:broadcast_conversation_update)
      conversation.update!(title: 'New Title')
      expect(conversation).to have_received(:broadcast_conversation_update)
    end

    it 'calls trigger_ai_classification on create' do
      allow(conversation).to receive(:trigger_ai_classification)
      conversation.save!
      expect(conversation).to have_received(:trigger_ai_classification)
    end
  end

  describe '#initialize_ai_status' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    
    it 'sets ai_status to ai_active if inbox has an active AI agent' do
      ai_agent = double('ai_agent', active_and_configured?: true)
      allow(inbox).to receive(:ai_agent).and_return(ai_agent)
      conv = build(:conversation, account: account, inbox: inbox)
      conv.save!
      expect(conv.ai_status).to eq('ai_active')
    end

    it 'leaves ai_status as ai_inactive if no active agent' do
      ai_agent = double('ai_agent', active_and_configured?: false)
      allow(inbox).to receive(:ai_agent).and_return(ai_agent)
      conv = build(:conversation, account: account, inbox: inbox)
      conv.save!
      expect(conv.ai_status).to eq('ai_inactive')
    end
  end

  describe '#trigger_ai_classification' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }

    it 'enqueues ConversationClassifierWorker if inbox has ai_classification enabled' do
      allow(inbox).to receive(:ai_classification?).and_return(true)
      expect(Ai::ConversationClassifierWorker).to receive(:perform_async)
      create(:conversation, account: account, inbox: inbox)
    end

    it 'does not enqueue if ai_classification is disabled' do
      allow(inbox).to receive(:ai_classification?).and_return(false)
      expect(Ai::ConversationClassifierWorker).not_to receive(:perform_async)
      create(:conversation, account: account, inbox: inbox)
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
        expect(conversation.conversation_members.where(member: other_user, role: :participant).count).to eq(1)
      end
    end
  end

  describe 'Instance Methods' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:user) { create(:user) }
    
    before do
      create(:account_user, account: account, user: user)
    end

    describe '#event_payload' do
      it 'returns a hash with conversation details' do
        payload = conversation.event_payload
        expect(payload[:id]).to eq(conversation.id)
        expect(payload[:status]).to eq(conversation.status)
        expect(payload[:identifier]).to eq(conversation.identifier)
        expect(payload[:assignee_id]).to eq(conversation.assignee_id)
      end
    end

    describe '#should_track_changes?' do
      it 'returns false if not persisted' do
        new_conv = build(:conversation)
        expect(new_conv.should_track_changes?).to be false
      end

      it 'returns true if there are meaningful changes' do
        conversation.update(title: 'New Title')
        expect(conversation.should_track_changes?).to be true
      end

      it 'returns false if only ignored attributes are changed' do
        conversation.update(last_activity_at: Time.current)
        expect(conversation.should_track_changes?).to be false
      end
    end

    describe '#mark_as_read_for' do
      it 'marks conversation member as read' do
        member = create(:conversation_member, conversation: conversation, member: user)
        allow(UnreadCounts::Reset).to receive(:call)
        
        conversation.mark_as_read_for(user)
        expect(member.reload.last_seen_at).to be_present
      end
    end

    describe '#notifiable_agents' do
      it 'returns directly assigned participants' do
        create(:conversation_member, conversation: conversation, member: user)
        expect(conversation.notifiable_agents).to include(user)
      end
    end
  end

  describe 'Additional Scopes' do
    let!(:account) { create(:account) }
    let!(:user) { create(:user) }
    let!(:conv) { create(:conversation, account: account) }

    describe '.not_assigned_to_user' do
      it 'returns conversations without an assignee' do
        expect(Conversation.not_assigned_to_user).to include(conv)
        conv.update!(assignee: user)
        expect(Conversation.not_assigned_to_user).not_to include(conv)
      end
    end

    describe '.current_conversations' do
      it 'returns conversations the user is a member of' do
        create(:conversation_member, conversation: conv, member: user)
        expect(Conversation.current_conversations(user)).to include(conv)
      end
    end
  end
end

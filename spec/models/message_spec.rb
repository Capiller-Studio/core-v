require 'rails_helper'

RSpec.describe Message, type: :model do
  subject { build(:message) }

  describe 'Associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:sender) }
    it { is_expected.to belong_to(:reply_to_message).class_name('Message').optional }
    it { is_expected.to have_many(:attachments).dependent(:destroy) }
    it { is_expected.to have_many(:reactions).class_name('MessageReaction').dependent(:destroy) }
    it { is_expected.to have_many(:replies).class_name('Message').with_foreign_key(:reply_to_message_id).dependent(:nullify) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(sent: 0, delivered: 1, read: 2, failed: 3) }
    it { is_expected.to define_enum_for(:content_type).with_values(text: 0, activity: 1, csat: 2) }
    it { is_expected.to define_enum_for(:visibility).with_values(personal: 0, global: 1) }
    it {
      is_expected.to define_enum_for(:source).with_values(
        email: 0, facebook_message: 1, whatsapp: 2, instagram_direct_message: 3,
        api: 4, web_widget: 5, sms: 6, telegram: 7, help_center: 8
      ).with_suffix(:source)
    }
  end

  describe '#incoming?' do
    it 'returns true when sender is a Customer' do
      message = build(:message, sender: build(:customer))
      expect(message.incoming?).to be true
    end

    it 'returns false when sender is a User' do
      message = build(:message, sender: build(:user))
      expect(message.incoming?).to be false
    end
  end

  describe '#outgoing?' do
    it 'returns true when sender is a User' do
      message = build(:message, sender: build(:user))
      expect(message.outgoing?).to be true
    end

    it 'returns true when sender is an Account' do
      message = build(:message, sender: build(:account))
      expect(message.outgoing?).to be true
    end

    it 'returns true when sender is an Ai::Agent' do
      message = build(:message, sender: build(:ai_agent))
      expect(message.outgoing?).to be true
    end

    it 'returns false when sender is a Customer' do
      message = build(:message, sender: build(:customer))
      expect(message.outgoing?).to be false
    end
  end

  describe 'Associations ' do
    # Just extending the previous block
    it { is_expected.to belong_to(:outbound_channel).optional }
    it { is_expected.to have_one(:csat_survey_response).class_name('Csat::SurveyResponse').dependent(:nullify) }
  end

  describe '#event_payload' do
    let(:message) { create(:message) }

    it 'returns the event payload hash' do
      payload = message.event_payload
      expect(payload[:id]).to eq(message.id)
      expect(payload[:content]).to eq(message.content)
      expect(payload[:status]).to eq(message.status)
      expect(payload[:source]).to eq(message.source)
      expect(payload[:is_edited]).to eq(false)
      expect(payload[:is_deleted]).to eq(false)
      expect(payload[:reactions]).to eq([])
    end
  end

  describe '#edit!' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, account: account, conversation: conversation, content: 'Original content') }

    it 'updates content, records edit history, and sets edited_at' do
      expect(message.edited?).to be false
      message.edit!('Updated content')
      expect(message.content).to eq('Updated content')
      expect(message.edited?).to be true
      expect(message.edited_at).to be_present
      expect(message.edit_history.first['content']).to eq('Original content')
    end
  end

  describe '#unsend!' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, account: account, conversation: conversation) }

    it 'sets deleted_at' do
      expect(message.deleted?).to be false
      message.unsend!
      expect(message.deleted?).to be true
      expect(message.deleted_at).to be_present
    end
  end

  describe 'Reply resolution and syncing' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:parent_message) { create(:message, account: account, conversation: conversation, external_id: 'parent_mid_123', content: 'Parent question') }

    it 'resolves reply_to_message from external_reply_to_id' do
      account.with_shard do
        parent_message
        reply = create(:message, account: account, conversation: conversation, external_reply_to_id: 'parent_mid_123')
        expect(reply.reply_to_message).to eq(parent_message)
      end
    end

    it 'syncs external_reply_to_id from reply_to_message' do
      account.with_shard do
        reply = create(:message, account: account, conversation: conversation, reply_to_message: parent_message)
        expect(reply.external_reply_to_id).to eq('parent_mid_123')
      end
    end
  end

  describe 'Callbacks' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    
    it 'calls broadcast_message_creation on create' do
      message = build(:message, account: account, conversation: conversation)
      allow(message).to receive(:broadcast_message_creation)
      message.save!
      expect(message).to have_received(:broadcast_message_creation)
    end

    it 'calls process_sla on create' do
      message = build(:message, account: account, conversation: conversation)
      allow(message).to receive(:process_sla)
      message.save!
      expect(message).to have_received(:process_sla)
    end


    it 'calls broadcast_message_update on status change' do
      message = create(:message, account: account, conversation: conversation)
      allow(message).to receive(:broadcast_message_update)
      message.update!(status: :delivered)
      expect(message).to have_received(:broadcast_message_update)
    end
    it 'calls trigger_language_detection on create' do
      message = build(:message, account: account, conversation: conversation)
      allow(message).to receive(:trigger_language_detection)
      message.save!
      expect(message).to have_received(:trigger_language_detection)
    end

    it 'calls trigger_thank_you_detector on create' do
      message = build(:message, account: account, conversation: conversation)
      allow(message).to receive(:trigger_thank_you_detector)
      message.save!
      expect(message).to have_received(:trigger_thank_you_detector)
    end

    it 'calls trigger_ai_agent on create' do
      message = build(:message, account: account, conversation: conversation)
      allow(message).to receive(:trigger_ai_agent)
      message.save!
      expect(message).to have_received(:trigger_ai_agent)
    end
  end

  describe '#trigger_language_detection' do
    let(:account) { create(:account) }
    let(:customer) { create(:customer, account: account, locale: 'en') }
    let(:conversation) { create(:conversation, account: account) }
    
    it 'enqueues DetectLanguageWorker if it is the first or second message from a customer with no locale' do
      expect(DetectLanguageWorker).to receive(:perform_async).twice
      create(:message, account: account, conversation: conversation, sender: customer)
      create(:message, account: account, conversation: conversation, sender: customer)
    end

    it 'does not enqueue if there are already 2 messages' do
      create(:message, account: account, conversation: conversation, sender: customer)
      create(:message, account: account, conversation: conversation, sender: customer)
      
      expect(DetectLanguageWorker).not_to receive(:perform_async)
      create(:message, account: account, conversation: conversation, sender: customer)
    end
    
    it 'does not enqueue if sender is not customer' do
      user = create(:user)
      expect(DetectLanguageWorker).not_to receive(:perform_async)
      create(:message, account: account, conversation: conversation, sender: user)
    end
  end

  describe '#trigger_thank_you_detector' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:customer) { create(:customer, account: account) }

    it 'enqueues ThankYouDetectorWorker if inbox has ai_thank_you_detection enabled and account has AI features' do
      allow(inbox).to receive(:ai_thank_you_detection?).and_return(true)
      allow(account).to receive(:feature_enabled?).and_call_original
      allow(account).to receive(:feature_enabled?).with(:ai_copilot).and_return(true)
      expect(Ai::ThankYouDetectorWorker).to receive(:perform_async)
      message = build(:message, account: account, conversation: conversation, sender: customer)
      allow(message).to receive(:inbox).and_return(inbox)
      allow(message).to receive(:account).and_return(account)
      message.save!
    end

    it 'does not enqueue if ai_thank_you_detection is disabled' do
      allow(inbox).to receive(:ai_thank_you_detection?).and_return(false)
      expect(Ai::ThankYouDetectorWorker).not_to receive(:perform_async)
      message = build(:message, account: account, conversation: conversation, sender: customer)
      allow(message).to receive(:inbox).and_return(inbox)
      message.save!
    end
  end

  describe '#trigger_ai_agent' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    # use build/save for conversation to avoid trigger_ai_classification mocking complexity
    let(:conversation) do
      conv = build(:conversation, account: account, inbox: inbox)
      conv.ai_status = :ai_active
      conv.save!
      conv
    end
    let(:customer) { create(:customer, account: account) }

    it 'enqueues AgentWorker if conversation is ai_active and inbox has an active agent' do
      ai_agent = double('ai_agent', active_and_configured?: true)
      allow(inbox).to receive(:ai_agent).and_return(ai_agent)
      allow(inbox).to receive(:ai_agent_id).and_return("agent-uuid")
      expect(Ai::AgentWorker).to receive(:perform_async)
      message = build(:message, account: account, conversation: conversation, sender: customer)
      allow(message).to receive(:inbox).and_return(inbox)
      message.save!
    end

    it 'forces handoff if agent is inactive but conversation was ai_active' do
      ai_agent = double('ai_agent', active_and_configured?: false)
      allow(inbox).to receive(:ai_agent).and_return(ai_agent)
      
      message = build(:message, account: account, conversation: conversation, sender: customer)
      allow(message).to receive(:inbox).and_return(inbox)
      message.save!
      expect(conversation.reload.ai_status).to eq('ai_handed_off')
    end
  end
end

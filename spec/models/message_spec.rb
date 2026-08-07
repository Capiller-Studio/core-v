require 'rails_helper'

RSpec.describe Message, type: :model do
  subject { build(:message) }

  describe 'Associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:sender) }
    it { is_expected.to have_many(:attachments).dependent(:destroy) }
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

    it 'calls deliver_contact_form_reply for outgoing help_center messages' do
      user = create(:user)
      message = build(:message, account: account, conversation: conversation, sender: user, source: :help_center)
      allow(message).to receive(:deliver_contact_form_reply)
      message.save!
      expect(message).to have_received(:deliver_contact_form_reply)
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
      allow_any_instance_of(Inbox).to receive(:ai_thank_you_detection?).and_return(true)
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:ai_copilot).and_return(true)
      expect(Ai::ThankYouDetectorWorker).to receive(:perform_async)
      create(:message, account: account, conversation: conversation, sender: customer)
    end

    it 'does not enqueue if ai_thank_you_detection is disabled' do
      allow_any_instance_of(Inbox).to receive(:ai_thank_you_detection?).and_return(false)
      expect(Ai::ThankYouDetectorWorker).not_to receive(:perform_async)
      create(:message, account: account, conversation: conversation, sender: customer)
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
      allow_any_instance_of(Inbox).to receive_message_chain(:ai_agent, :active_and_configured?).and_return(true)
      allow_any_instance_of(Inbox).to receive(:ai_agent_id).and_return("agent-uuid")
      expect(Ai::AgentWorker).to receive(:perform_async)
      create(:message, account: account, conversation: conversation, sender: customer)
    end

    it 'forces handoff if agent is inactive but conversation was ai_active' do
      allow_any_instance_of(Inbox).to receive_message_chain(:ai_agent, :active_and_configured?).and_return(false)
      
      create(:message, account: account, conversation: conversation, sender: customer)
      expect(conversation.reload.ai_status).to eq('ai_handed_off')
    end
  end
end

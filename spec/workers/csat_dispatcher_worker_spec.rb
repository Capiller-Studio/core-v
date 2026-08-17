# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsatDispatcherWorker, type: :worker do
  let(:account) { create(:account) }
  let(:csat_survey) { create(:csat_survey, account: account, prompt: 'Rate us {{ customer.name }}') }
  let(:inbox) { create(:inbox, account: account, csat_survey: csat_survey) }
  let(:customer) { create(:customer, account: account, name: 'Alice Customer') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :resolved) }

  before do
    allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
    allow_any_instance_of(Account).to receive(:feature_enabled?).with(:csat).and_return(true)
    create(:conversation_member, conversation: conversation, member: customer)
    inbox.update_columns(flags: 1) # csat_survey_enabled flag
  end

  describe '#perform' do
    it 'creates a pending Csat::SurveyResponse, creates csat message, and enqueues delivery' do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String))

      expect {
        described_class.new.perform(conversation.id)
      }.to change(Csat::SurveyResponse, :count).by(1)

      survey_response = conversation.csat_survey_responses.last
      expect(survey_response.status).to eq('pending')
      expect(survey_response.customer_id).to eq(customer.id)

      message = conversation.messages.last
      expect(message.content_type).to eq('csat')
      expect(message.data['csat_response_id']).to eq(survey_response.id)
    end

    it 'returns early if conversation is not resolved' do
      conversation.update_column(:status, 0) # active
      expect(Messages::DeliveryWorker).not_to receive(:perform_async)

      described_class.new.perform(conversation.id)
    end

    it 'returns early if a pending survey response already exists' do
      create(:csat_survey_response, account: account, conversation: conversation, customer: customer, status: :pending)
      expect(Messages::DeliveryWorker).not_to receive(:perform_async)

      described_class.new.perform(conversation.id)
    end
  end
end

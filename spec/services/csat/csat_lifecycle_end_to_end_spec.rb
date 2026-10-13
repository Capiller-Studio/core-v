# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CSAT Survey Lifecycle and Feedback Submission End-To-End', type: :service do
  let(:account) { create(:account) }
  let(:email_template) do
    create(:email_template,
      account: account,
      name: 'Custom CSAT Layout',
      template_type: :csat_survey,
      body: '<p>How did we do? {{ csat_rating_links }}</p>'
    )
  end
  let(:csat_survey) do
    create(:csat_survey,
      account: account,
      name: 'Quarterly Support Survey',
      prompt: 'Rate your experience with {{ customer.name }}',
      portal_title: 'Support Experience Rating',
      portal_subtitle: 'Your feedback matters to us',
      portal_feedback_label: 'Any comments?',
      email_template: email_template
    )
  end
  let(:inbox) { create(:inbox, account: account, csat_survey: csat_survey, flags: 1) } # flags: 1 enables csat_survey_enabled
  let(:customer) { create(:customer, account: account, name: 'Grace Hopper', email: 'grace@example.com') }
  let(:conversation) do
    create(:conversation,
      account: account,
      inbox: inbox,
      status: :resolved,
      status_changed_at: Time.current
    )
  end

  before do
    allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
    allow_any_instance_of(Account).to receive(:feature_enabled?).with(:csat).and_return(true)
    create(:conversation_member, conversation: conversation, member: customer)
    allow(Messages::DeliveryWorker).to receive(:perform_async)
  end

  describe 'Full CSAT Lifecycle: Resolution Trigger -> Survey Message -> Customer Feedback' do
    it 'dispatches survey upon resolution, accepts valid rating and feedback, and updates metrics' do
      # 1. Trigger worker upon conversation resolution
      expect {
        CsatDispatcherWorker.new.perform(conversation.id)
      }.to change(Csat::SurveyResponse, :count).by(1)

      survey_response = conversation.csat_survey_responses.last
      expect(survey_response.status).to eq('pending')
      expect(survey_response.customer).to eq(customer)
      expect(survey_response.csat_survey).to eq(csat_survey)

      # 2. Associated message created with csat content type
      csat_message = conversation.messages.last
      expect(csat_message.content_type).to eq('csat')
      expect(csat_message.csat_survey_response).to eq(survey_response)

      # 3. Customer submits 5-star rating with commentary
      survey_response.update!(
        rating: 5,
        content: 'Fantastic resolution speed! Thank you so much.',
        status: :submitted
      )

      expect(survey_response.reload.status).to eq('submitted')
      expect(survey_response.rating).to eq(5)
      expect(survey_response.content).to eq('Fantastic resolution speed! Thank you so much.')

      # 4. Check account average score calculation
      avg_score = Csat::SurveyResponse.where(account_id: account.id).average(:rating).to_f
      expect(avg_score).to eq(5.0)
    end
  end

  describe 'CSAT Edge Cases and Guardrails' do
    it 'rejects ratings outside the allowed 1 to 5 scale' do
      survey_response = create(:csat_survey_response,
        account: account,
        conversation: conversation,
        customer: customer,
        status: :pending
      )

      expect {
        survey_response.update!(rating: 6)
      }.to raise_error(ActiveRecord::RecordInvalid, /Rating is not included in the list/)

      expect {
        survey_response.update!(rating: 0)
      }.to raise_error(ActiveRecord::RecordInvalid, /Rating is not included in the list/)
    end

    it 'does not dispatch when conversation is not resolved' do
      active_conversation = create(:conversation, account: account, inbox: inbox, status: :active)
      create(:conversation_member, conversation: active_conversation, member: customer)

      expect {
        CsatDispatcherWorker.new.perform(active_conversation.id)
      }.not_to change(Csat::SurveyResponse, :count)
    end

    it 'prevents duplicate dispatch if a pending survey response already exists' do
      create(:csat_survey_response,
        account: account,
        conversation: conversation,
        customer: customer,
        status: :pending
      )

      expect {
        CsatDispatcherWorker.new.perform(conversation.id)
      }.not_to change(Csat::SurveyResponse, :count)
    end

    it 'does not dispatch when inbox has CSAT disabled' do
      disabled_inbox = create(:inbox, account: account, flags: 0)
      unflagged_conversation = create(:conversation, account: account, inbox: disabled_inbox, status: :resolved)
      create(:conversation_member, conversation: unflagged_conversation, member: customer)

      expect {
        CsatDispatcherWorker.new.perform(unflagged_conversation.id)
      }.not_to change(Csat::SurveyResponse, :count)
    end

    it 'supports survey responses without custom survey, falling back cleanly' do
      inbox_without_custom_survey = create(:inbox, account: account, csat_survey: nil, flags: 1)
      fallback_conversation = create(:conversation, account: account, inbox: inbox_without_custom_survey, status: :resolved)
      create(:conversation_member, conversation: fallback_conversation, member: customer)

      expect {
        CsatDispatcherWorker.new.perform(fallback_conversation.id)
      }.to change(Csat::SurveyResponse, :count).by(1)

      response = fallback_conversation.csat_survey_responses.last
      expect(response.csat_survey).to be_nil
      expect(response.status).to eq('pending')
    end
  end
end

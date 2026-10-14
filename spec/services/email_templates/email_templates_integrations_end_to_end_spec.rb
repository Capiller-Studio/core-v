# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Email Templates and Multi-Module Integrations End-To-End', type: :service do
  let(:account) { create(:account, name: 'Stark Industries') }
  let(:layout) do
    create(:email_template_layout,
      account: account,
      name: 'Default Corporate Header Layout',
      body: '<html><body><header>Stark Support</header>{{ content }}<footer>&copy; Stark</footer></body></html>'
    )
  end
  let(:email_template) do
    create(:email_template,
      account: account,
      name: 'Ticket Triage Response',
      template_type: :conversation_reply,
      status: :active,
      email_template_layout: layout,
      subject: 'Update on Ticket #{{ conversation.identifier }}',
      body: 'Hello {{ customer.name }}, your ticket #{{ conversation.identifier }} is being handled by {{ agent.name }}. Welcome to {{ account.name }}.'
    )
  end
  let(:inbox) { create(:inbox, account: account, name: 'Email Inbound') }
  let(:agent) { create(:user, name: 'Tony Stark', email: 'tony@stark.com') }
  let(:customer) { create(:customer, account: account, name: 'Peter Parker', email: 'peter@dailybugle.com') }
  let(:conversation) do
    create(:conversation,
      account: account,
      inbox: inbox,
      assignee: agent,
      identifier: 1042
    )
  end

  before do
    create(:conversation_member, conversation: conversation, member: customer)
    allow(Messages::DeliveryWorker).to receive(:perform_async)
  end

  describe 'Liquid Template Compilation and Rendering' do
    it 'interpolates complex context variables into template subject and body' do
      variables = {
        'customer' => { 'name' => 'Peter Parker', 'email' => 'peter@dailybugle.com' },
        'agent' => { 'name' => 'Tony Stark', 'email' => 'tony@stark.com' },
        'conversation' => { 'identifier' => '1042' },
        'account' => { 'name' => 'Stark Industries' }
      }

      rendered_subject = email_template.render_subject(variables)
      rendered_body = email_template.render_body(variables)

      expect(rendered_subject).to eq('Update on Ticket #1042')
      expect(rendered_body).to eq('Hello Peter Parker, your ticket #1042 is being handled by Tony Stark. Welcome to Stark Industries.')
    end
  end

  describe 'Module Integration 1: Automations SendEmailToCustomer Action' do
    it 'validates parameters and enqueues background delivery worker' do
      expect(Automations::EmailDeliveryWorker).to receive(:perform_async).with(
        email_template.id,
        customer.id,
        conversation.id,
        account.id
      )

      Automations::Actions::SendEmailToCustomer.call(
        resource: conversation,
        account: account,
        params: { email_template_id: email_template.id },
        actor: nil
      )
    end

    it 'executes EmailDeliveryWorker, renders template with conversation context, and creates outgoing message' do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String))

      expect {
        Automations::EmailDeliveryWorker.new.perform(
          email_template.id,
          customer.id,
          conversation.id,
          account.id
        )
      }.to change(conversation.messages, :count).by(1)

      sent_message = conversation.messages.last
      expect(sent_message.content).to include('Hello Peter Parker')
      expect(sent_message.content).to include('ticket #1042')
      expect(sent_message.content).to include('Tony Stark')
      expect(sent_message.content).to include('Stark Industries')
      expect(sent_message.data['email_template_id']).to eq(email_template.id)
      expect(sent_message.data['target_email']).to eq('peter@dailybugle.com')
    end

    it 'raises error when conversation has no customer or customer has no email' do
      conversation_without_customer = create(:conversation, account: account, inbox: inbox)

      expect {
        Automations::Actions::SendEmailToCustomer.call(
          resource: conversation_without_customer,
          account: account,
          params: { email_template_id: email_template.id },
          actor: nil
        )
      }.to raise_error(RuntimeError, /No customer found on conversation/)
    end
  end

  describe 'Module Integration 2: CSAT Surveys with Custom Email Template' do
    let(:csat_template) do
      create(:email_template,
        account: account,
        name: 'CSAT Template',
        template_type: :csat_survey,
        status: :active,
        subject: 'Rate your experience with {{ account.name }}',
        body: 'Hi {{ customer.name }}, please rate our support for conversation #{{ conversation.identifier }}: {{ csat.survey_url }}'
      )
    end

    let(:csat_survey) do
      create(:csat_survey,
        account: account,
        name: 'Stark Satisfaction',
        email_template: csat_template
      )
    end

    it 'links email template to CSAT survey and renders survey variables' do
      expect(csat_survey.email_template).to eq(csat_template)

      rendered = csat_template.render_body({
        'customer' => { 'name' => 'Peter Parker' },
        'conversation' => { 'identifier' => '1042' },
        'csat' => { 'survey_url' => 'https://deskbolic.com/csat/token-xyz' }
      })

      expect(rendered).to include('Hi Peter Parker')
      expect(rendered).to include('conversation #1042')
      expect(rendered).to include('https://deskbolic.com/csat/token-xyz')
    end
  end

  describe 'Edge Cases: Resilience and Syntax Safety' do
    it 'handles missing or blank variables gracefully without crashing' do
      sparse_template = create(:email_template,
        account: account,
        template_type: :conversation_reply,
        body: 'Customer: {{ customer.name | default: "Valued Customer" }} - Missing: {{ unknown.variable }}'
      )

      rendered = sparse_template.render_body({})
      expect(rendered).to eq('Customer: Valued Customer - Missing: ')
    end
  end
end

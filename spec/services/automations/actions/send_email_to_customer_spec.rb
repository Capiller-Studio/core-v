require 'rails_helper'

RSpec.describe Automations::Actions::SendEmailToCustomer do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:template) { create(:email_template, account: account) }

  describe '#call' do
    context 'when email_template_id is missing' do
      let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

      it 'raises an error' do
        expect { service.call }.to raise_error('email_template_id is required')
      end
    end

    context 'when email_template is not found' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { email_template_id: 999999 }) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when no customer is found on the conversation' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { email_template_id: template.id }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('No customer found on conversation')
      end
    end

    context 'when customer has no email' do
      let(:customer) { create(:customer, account: account, email: nil) }
      let(:service) { described_class.new(resource: conversation, account: account, params: { email_template_id: template.id }) }

      before do
        create(:conversation_member, conversation: conversation, member: customer)
      end

      it 'raises an error' do
        expect { service.call }.to raise_error('Customer has no email')
      end
    end

    context 'when valid' do
      let(:customer) { create(:customer, account: account, email: 'test@example.com') }
      let(:service) { described_class.new(resource: conversation, account: account, params: { email_template_id: template.id }) }

      before do
        create(:conversation_member, conversation: conversation, member: customer)
        stub_const('Automations::EmailDeliveryWorker', double('EmailDeliveryWorker', perform_async: true))
      end

      it 'enqueues the EmailDeliveryWorker' do
        expect(Automations::EmailDeliveryWorker).to receive(:perform_async).with(template.id, customer.id, conversation.id, account.id)
        service.call
      end
    end
  end
end

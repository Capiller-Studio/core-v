require 'rails_helper'

RSpec.describe Customers::CustomerInboxCreator do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account, email: 'customer@test.com', full_phone_number: '+15551234') }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(Identities::AutomationManager).to receive(:call)
  end

  describe '#call' do
    context 'when inbox is email channel' do
      let(:channel) { create(:channel_email, account: account) }
      let(:inbox) { create(:inbox, account: account, channel: channel) }
      let(:service) { described_class.new(account: account, customer: customer, inbox: inbox) }

      it 'creates customer_inbox with email as external_id' do
        customer_inbox = nil
        expect { customer_inbox = service.call }.to change(CustomerInbox, :count).by(1)
        
        expect(customer_inbox.external_id).to eq('customer@test.com')
        expect(customer_inbox.customer).to eq(customer)
        expect(customer_inbox.inbox).to eq(inbox)
      end

      it 'calls AutomationManager' do
        expect(Identities::AutomationManager).to receive(:call).with(
          customer: customer, inbox: inbox, external_id: 'customer@test.com'
        )
        service.call
      end
    end

    context 'when external_id is provided' do
      let(:channel) { create(:channel_email, account: account) }
      let(:inbox) { create(:inbox, account: account, channel: channel) }
      let(:service) { described_class.new(account: account, customer: customer, inbox: inbox, external_id: 'custom-ext-123') }

      it 'uses the provided external_id' do
        customer_inbox = nil
        expect { customer_inbox = service.call }.to change(CustomerInbox, :count).by(1)
        
        expect(customer_inbox.external_id).to eq('custom-ext-123')
      end
    end

    context 'when inbox is contact form or web widget channel' do
      let(:channel) { create(:channel_contact_form, account: account) }
      let(:inbox) { create(:inbox, account: account, channel: channel) }

      it 'prioritizes customer.external_id when present' do
        customer_with_ext = create(:customer, account: account, external_id: 'ext-999', email: 'cust@example.com')
        service = described_class.new(account: account, customer: customer_with_ext, inbox: inbox)

        inbox_record = service.call
        expect(inbox_record.external_id).to eq('ext-999')
      end

      it 'falls back to customer.id when no external_id, email, phone or username are present' do
        anon_customer = create(:customer, account: account, email: nil, full_phone_number: nil, external_id: nil)
        service = described_class.new(account: account, customer: anon_customer, inbox: inbox)

        inbox_record = service.call
        expect(inbox_record.external_id).to eq(anon_customer.id.to_s)
      end

      it 'guarantees a collision-checked UUID when customer.id already exists as an external_id' do
        anon_customer = create(:customer, account: account, email: nil, full_phone_number: nil, external_id: nil)
        # Pre-occupy customer.id as an external_id in the inbox
        other_customer = create(:customer, account: account)
        inbox.customer_inboxes.create!(customer: other_customer, external_id: anon_customer.id.to_s)

        service = described_class.new(account: account, customer: anon_customer, inbox: inbox)
        inbox_record = service.call

        expect(inbox_record.external_id).not_to eq(anon_customer.id.to_s)
        expect(inbox_record.external_id).to match(/\A[0-9a-f\-]{36}\z/)
      end
    end
  end
end

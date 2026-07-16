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
  end
end

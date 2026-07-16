require 'rails_helper'

RSpec.describe PaymentGateway::Base do
  let(:account) { double('Account', billing_data: { 'test_provider_customer_id' => 'cust-123' }) }
  let(:service) { described_class.new(account) }

  before do
    allow(service).to receive(:provider_name).and_return('test_provider')
  end

  describe '#gateway_customer_id' do
    it 'returns the customer id from billing data' do
      expect(service.send(:gateway_customer_id)).to eq('cust-123')
    end
  end

  describe '#store_customer_id' do
    it 'updates the account billing_data' do
      expect(account).to receive(:update!).with(billing_data: { 'test_provider_customer_id' => 'new-cust-456' })
      service.send(:store_customer_id, 'new-cust-456')
    end
  end

  describe 'NotImplementedError methods' do
    it 'raises NotImplementedError for abstract methods' do
      expect { service.create_customer }.to raise_error(NotImplementedError)
      expect { service.retrieve_customer('123') }.to raise_error(NotImplementedError)
      expect { service.add_payment_method('token') }.to raise_error(NotImplementedError)
      expect { service.remove_payment_method('123') }.to raise_error(NotImplementedError)
      expect { service.list_payment_methods }.to raise_error(NotImplementedError)
      expect { service.charge(amount: 100, currency: 'USD') }.to raise_error(NotImplementedError)
      expect { service.refund(transaction_external_id: '123') }.to raise_error(NotImplementedError)
      expect { service.create_subscription(plan: 'basic', billing_cycle: 'monthly') }.to raise_error(NotImplementedError)
      expect { service.cancel_subscription('123') }.to raise_error(NotImplementedError)
      expect { service.retrieve_subscription('123') }.to raise_error(NotImplementedError)
    end
  end
end

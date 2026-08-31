require 'rails_helper'

RSpec.describe Customers::CustomerCreator do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_email, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: channel) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(Customers::CustomerInboxCreator).to receive(:call) do |args|
      double('CustomerInbox', customer: args[:customer])
    end
    allow(Utilities::ActiveStorageDownloader).to receive(:attach).and_return(true)
  end

  describe '#call' do
    context 'when customer already exists in the inbox by external_id' do
      let!(:customer) { create(:customer, account: account, email: 'exist@example.com') }
      let!(:customer_inbox) { CustomerInbox.create!(customer: customer, inbox: inbox, external_id: 'ext-123') }
      let(:service) { described_class.new(account: account, inbox: inbox, external_id: 'ext-123') }

      it 'returns the existing customer' do
        expect { service.call }.not_to change(Customer, :count)
        expect(service.call).to eq(customer)
      end
    end

    context 'when customer has an existing identity matching the channel' do
      let(:fb_channel) do
        allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
        create(:channel_facebook_page, account: account)
      end
      let(:fb_inbox) { create(:inbox, account: account, channel: fb_channel) }
      let!(:existing_customer) { create(:customer, account: account, name: 'Identified User') }
      let!(:identity) { create(:identity, customer: existing_customer, identity_type: :facebook, identifier: 'fb-user-999', account: account) }
      let(:service) { described_class.new(account: account, inbox: fb_inbox, external_id: 'fb-user-999') }

      it 'finds and returns the customer via identity' do
        expect { service.call }.not_to change(Customer, :count)
        expect(service.call).to eq(existing_customer)
      end
    end

    context 'when creating a new customer' do
      let(:params) do
        {
          name: 'Jane Doe',
          first_name: 'Jane',
          last_name: 'Doe',
          gender: 'female',
          phone_code: '+1',
          phone_number: '5551234',
          locale: 'English'
        }
      end
      let(:service) do
        described_class.new(
          account: account,
          inbox: inbox,
          email: 'jane@example.com',
          external_id: 'ext-456',
          params: params
        )
      end

      it 'creates a new customer and returns it' do
        result = nil
        expect { result = service.call }.to change(Customer, :count).by(1)
        
        expect(result.name).to eq('Jane Doe')
        expect(result.email).to eq('jane@example.com')
        expect(result.full_phone_number).to eq('+15551234')
        expect(result.gender).to eq('female')
        expect(result.locale).to eq('en')
      end

      it 'calls CustomerInboxCreator' do
        expect(Customers::CustomerInboxCreator).to receive(:call).with(
          customer: kind_of(Customer),
          inbox: inbox,
          external_id: 'ext-456',
          account: account
        )
        service.call
      end

      it 'attaches avatar' do
        expect(Utilities::ActiveStorageDownloader).to receive(:attach).with(
          record: kind_of(Customer),
          attachment_name: :avatar,
          url: /avatar\.iran\.liara\.run\/public\/girl/
        )
        service.call
      end
    end
  end
end

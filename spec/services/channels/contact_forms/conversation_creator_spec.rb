require 'rails_helper'

RSpec.describe Channels::ContactForms::ConversationCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  
  let(:cf1) { double('CustomField', key: 'user_email', mapped_to: 'customer.email', entity_type: nil) }
  let(:cf2) { double('CustomField', key: 'order_id', mapped_to: nil, entity_type: 'conversation') }
  let(:cf3) { double('CustomField', key: 'message', mapped_to: 'message.content', entity_type: nil) }
  
  let(:channel) do
    double('Channel::ContactForm', 
      account: account, 
      primary_inbox: inbox, 
      custom_fields: [cf1, cf2, cf3],
      outbound_channel: double('OutboundChannel'),
      send_confirmation_email?: true
    )
  end
  
  let(:form_params) { { 'user_email' => 'test@form.com', 'order_id' => '12345', 'message' => 'Help me' } }
  
  let(:service) do
    described_class.new(
      contact_form_channel: channel,
      form_params: form_params,
      attachments: []
    )
  end

  describe '#call' do
    let(:customer) { double('Customer') }
    let(:conversation) { double('Conversation', conversation_members: double('Members', create!: true)) }
    let(:mailer_mock) { double('Mailer') }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::ContactForms::MessageCreator', double('MessageCreator'))
      stub_const('ContactFormMailer', double('ContactFormMailer'))

      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)
      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::ContactForms::MessageCreator).to receive(:call)
      
      allow(ContactFormMailer).to receive(:confirmation_email).with(conversation).and_return(mailer_mock)
      allow(mailer_mock).to receive(:deliver_later)
    end

    it 'creates customer, conversation, message, and sends email' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(
          email: 'test@form.com',
          external_id: 'test@form.com'
        )
      )

      expect(account.conversations).to receive(:create!).with(
        hash_including(
          source: :help_center,
          data: { 'order_id' => '12345' }
        )
      )

      expect(Channels::ContactForms::MessageCreator).to receive(:call).with(
        hash_including(
          content: 'Help me',
          attachments: []
        )
      )

      expect(ContactFormMailer).to receive(:confirmation_email).with(conversation)

      result = service.call
      expect(result).to eq(conversation)
    end
  end
end

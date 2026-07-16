require 'rails_helper'

RSpec.describe Channels::WebWidgets::ConversationCreator do
  let(:channel) { double('Channel::WebWidget', account: account, primary_inbox: inbox, fallback_channel: double('FallbackChannel')) }
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox') }
  
  let(:contact_params) { { external_id: 'ext123', email: 'test@web.com', name: 'Web User' } }
  let(:conversation_data) { { title: 'Need Help', priority: 'high', data: { 'browser' => 'chrome' } } }
  
  let(:service) do
    described_class.new(
      web_widget_channel: channel,
      contact_params: contact_params,
      content: 'Hello Help',
      attachments: [],
      account: account,
      conversation_data: conversation_data
    )
  end

  describe '#call' do
    let(:customer) { double('Customer') }
    let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::WebWidgets::MessageCreator', double('MessageCreator'))

      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::WebWidgets::MessageCreator).to receive(:call)
    end

    it 'creates customer, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(
          external_id: 'ext123',
          email: 'test@web.com',
          params: hash_including(name: 'Web User')
        )
      )

      expect(account.conversations).to receive(:create!).with(
        hash_including(
          source: :web_widget,
          title: 'Need Help',
          priority: 'high',
          data: { 'browser' => 'chrome' }
        )
      )

      expect(Channels::WebWidgets::MessageCreator).to receive(:call).with(
        hash_including(
          content: 'Hello Help',
          attachments: []
        )
      )

      result = service.call
      expect(result).to eq(conversation)
    end
  end
end

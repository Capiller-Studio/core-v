require 'rails_helper'

RSpec.describe Channels::Custom::ConversationCreator do
  let(:channel) { double('Channel::Custom', account: account, primary_inbox: inbox) }
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox') }
  
  let(:customer_params) { { external_id: 'ext123', email: 'test@custom.com', name: 'Custom User' } }
  let(:conversation_data) { { 'title' => 'Custom Chat', 'priority' => 'low', 'data' => { 'meta' => 'data' } } }
  
  let(:service) do
    described_class.new(
      custom_channel: channel,
      customer_params: customer_params,
      content: 'Hello World',
      attachments: [],
      account: account,
      conversation_data: conversation_data,
      external_id: 'conv_ext_1'
    )
  end

  describe '#call' do
    let(:customer) { double('Customer') }
    let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::Custom::MessageCreator', double('MessageCreator'))

      allow(account).to receive_message_chain(:conversations, :find_by).and_return(nil)
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)

      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::Custom::MessageCreator).to receive(:call)
    end

    it 'creates customer, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(
          external_id: 'ext123',
          email: 'test@custom.com',
          params: hash_including(name: 'Custom User')
        )
      )

      expect(account.conversations).to receive(:create!).with(
        hash_including(
          source: :custom,
          title: 'Custom Chat',
          priority: 'low',
          data: { 'meta' => 'data' },
          external_id: 'conv_ext_1'
        )
      )

      expect(Channels::Custom::MessageCreator).to receive(:call).with(
        hash_including(
          content: 'Hello World',
          attachments: []
        )
      )

      result = service.call
      expect(result).to eq(conversation)
    end

    context 'when conversation with external_id exists' do
      before do
        allow(account).to receive_message_chain(:conversations, :find_by).with(external_id: 'conv_ext_1', inbox: inbox).and_return(conversation)
      end

      it 'uses existing conversation and does not create a new one' do
        expect(account.conversations).not_to receive(:create!)
        expect(service).not_to receive(:find_or_reopen_conversation)

        result = service.call
        expect(result).to eq(conversation)
      end
    end
  end
end

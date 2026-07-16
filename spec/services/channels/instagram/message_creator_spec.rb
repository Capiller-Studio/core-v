require 'rails_helper'

RSpec.describe Channels::Instagram::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:instagram_channel) { double('InstagramChannel', access_token: 'token') }
  
  let(:parsed_message) do 
    double('ParsedMessage', 
      mid: 'ig_mid_123', 
      reply_to_mid: 'ig_mid_0', 
      content: 'Hello IG',
      attachments: attachments,
      message: { is_unsupported: false }
    ) 
  end
  let(:attachments) { [] }
  
  let(:service) do
    described_class.new(
      parsed_message: parsed_message, 
      account: account, 
      inbox: inbox, 
      sender: sender, 
      conversation: conversation,
      instagram_channel: instagram_channel
    )
  end

  before do
    allow(messages_assoc).to receive(:find_by).with(external_id: 'ig_mid_123').and_return(nil)
  end

  describe '#call' do
    it 'creates a message' do
      message = double('Message', attachments: [])
      expect(messages_assoc).to receive(:create!).with(
        hash_including(
          content: 'Hello IG',
          external_id: 'ig_mid_123',
          data: { is_unsupported: false }
        )
      ).and_return(message)

      expect(service.call).to eq(message)
    end
  end
end

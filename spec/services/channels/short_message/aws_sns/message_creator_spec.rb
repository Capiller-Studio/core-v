require 'rails_helper'

RSpec.describe Channels::ShortMessage::AwsSns::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:short_message_channel) { double('Channel::ShortMessage') }

  let(:sns_message) do
    { "messageBody" => "Hello AWS", "originationNumber" => "+12345" }.to_json
  end

  let(:parsed_message) do
    { "MessageId" => "MSG_AWS_1", "Message" => sns_message }
  end

  let(:service) do
    described_class.new(
      parsed_message: parsed_message, account: account, inbox: inbox, sender: sender, conversation: conversation, short_message_channel: short_message_channel
    )
  end

  before do
    allow(messages_assoc).to receive(:find_by).and_return(nil)
  end

  describe '#call' do
    it 'creates a message from parsed AWS MessageBody' do
      message_record = double('Message')
      expect(messages_assoc).to receive(:create!).with(
        hash_including(
          content: "Hello AWS",
          external_id: "MSG_AWS_1"
        )
      ).and_return(message_record)

      expect(service.call).to eq(message_record)
    end
  end
end

require 'rails_helper'

RSpec.describe Channels::ContactForms::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:attachments) { [] }
  let(:service) do
    described_class.new(
      account: account, inbox: inbox, conversation: conversation, sender: sender, content: 'Hello Form', attachments: attachments
    )
  end

  describe '#call' do
    let(:message_record) { double('Message', attachments: message_attachments_assoc) }
    let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }

    before do
      allow(messages_assoc).to receive(:create!).and_return(message_record)
    end

    it 'creates a text message' do
      expect(messages_assoc).to receive(:create!).with(
        hash_including(
          content: 'Hello Form',
          source: :help_center
        )
      )

      expect(service.call).to eq(message_record)
    end

    context 'with attachments' do
      let(:file) { double('File', content_type: 'image/png') }
      let(:attachments) { [file] }

      it 'creates and attaches files' do
        attachment_record = double('AttachmentRecord', file: double('ActiveStorageFile', attach: true))
        
        expect(message_attachments_assoc).to receive(:build).with(
          hash_including(attachment_type: :image)
        ).and_return(attachment_record)
        
        expect(attachment_record.file).to receive(:attach).with(file)
        expect(attachment_record).to receive(:save!)

        service.call
      end
    end
  end
end

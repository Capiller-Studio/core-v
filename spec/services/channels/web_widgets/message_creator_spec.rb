require 'rails_helper'

RSpec.describe Channels::WebWidgets::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:attachments) { [] }
  let(:service) do
    described_class.new(
      account: account, inbox: inbox, conversation: conversation, sender: sender, content: 'Hello Web Widget', attachments: attachments
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
          content: 'Hello Web Widget',
          source: :web_widget
        )
      )

      expect(service.call).to eq(message_record)
    end

    context 'with attachments' do
      let(:file1) { double('File', content_type: 'image/png') }
      let(:file2) { double('File', content_type: 'application/pdf') }
      let(:attachments) { [file1, file2] }

      it 'creates and attaches files' do
        attachment_record1 = double('AttachmentRecord', file: double('ActiveStorageFile1', attach: true))
        attachment_record2 = double('AttachmentRecord', file: double('ActiveStorageFile2', attach: true))
        
        expect(message_attachments_assoc).to receive(:build).with(
          hash_including(attachment_type: :image)
        ).and_return(attachment_record1)
        expect(attachment_record1.file).to receive(:attach).with(file1)
        expect(attachment_record1).to receive(:save!)

        expect(message_attachments_assoc).to receive(:build).with(
          hash_including(attachment_type: :file)
        ).and_return(attachment_record2)
        expect(attachment_record2.file).to receive(:attach).with(file2)
        expect(attachment_record2).to receive(:save!)

        service.call
      end
    end
  end
end

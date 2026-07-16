require 'rails_helper'

RSpec.describe Mailboxes::MessageCreator do
  let(:account) { create(:account) }

  around do |example|
    Current.set(account: account) { example.run }
  end
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:sender) { create(:user) }
  let(:mail) { double('Mail', message_id: 'msg-123') }
  
  let(:parsed_mail) do
    double('ParsedMail',
      in_reply_to: 'reply-123',
      references: ['ref-1', 'ref-2'],
      original_sender: 'sender@example.com',
      subject: 'Hello World',
      html_content_parsed: '<p>Hi</p>',
      text_content_parsed: 'Hi',
      attachments: []
    )
  end

  let(:service) do
    described_class.new(
      mail: mail,
      parsed_mail: parsed_mail,
      account: account,
      inbox: inbox,
      sender: sender,
      conversation: conversation
    )
  end

  describe '#call' do
    it 'creates a message with the correct attributes' do
      message = nil
      expect { message = service.call }.to change(Message, :count).by(1)

      expect(message.account_id).to eq(account.id)
      expect(message.inbox).to eq(inbox)
      expect(message.conversation).to eq(conversation)
      expect(message.sender).to eq(sender)
      expect(message.content).to eq('<p>Hi</p>')
      expect(message.external_id).to eq('msg-123')
      expect(message.data['email']['message_id']).to eq('msg-123')
      expect(message.data['email']['in_reply_to']).to eq('reply-123')
      expect(message.data['email']['references']).to eq(['ref-1', 'ref-2'])
      expect(message.data['email']['from']).to eq('sender@example.com')
      expect(message.data['email']['subject']).to eq('Hello World')
    end

    context 'when the message already exists' do
      before do
        create(:message, account: account, conversation: conversation, external_id: 'msg-123')
      end

      it 'does not create a duplicate message' do
        expect { service.call }.not_to change(Message, :count)
      end

      it 'returns the existing message' do
        expect(service.call.external_id).to eq('msg-123')
      end
    end

    context 'when processing attachments' do
      let(:blob) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new('test'), filename: 'test.txt') }
      let(:inline_blob) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new('img'), filename: 'test.png') }
      
      let(:regular_attachment) do
        {
          original: double('Attachment', inline?: false),
          blob: blob
        }
      end

      let(:inline_attachment) do
        {
          original: double('Attachment', inline?: true, cid: 'cid-123', filename: 'test.png'),
          blob: inline_blob
        }
      end

      before do
        allow(Rails.application.routes.url_helpers).to receive(:url_for).and_return('http://test/test.png')
        allow(parsed_mail).to receive(:attachments).and_return([regular_attachment, inline_attachment])
        allow(parsed_mail).to receive(:html_content_parsed).and_return('<img src="cid:cid-123">')
        allow(parsed_mail).to receive(:text_content_parsed).and_return('See image [image: test.png]')
      end

      it 'creates regular attachments' do
        service = described_class.new(
          mail: mail, parsed_mail: parsed_mail, account: account,
          inbox: inbox, sender: sender, conversation: conversation
        )
        
        message = nil
        expect { message = service.call }.to change(Attachment, :count).by(1)
        
        expect(message.attachments.first.file.filename.to_s).to eq('test.txt')
      end

      it 'replaces cid in html content with inline attachment url' do
        service = described_class.new(
          mail: mail, parsed_mail: parsed_mail, account: account,
          inbox: inbox, sender: sender, conversation: conversation
        )
        
        message = service.call
        expect(message.content).to match(/http.*test.png/)
        expect(message.content).not_to include('cid:cid-123')
      end

      it 'replaces text image placeholder in text content with inline attachment url' do
        allow(parsed_mail).to receive(:html_content_parsed).and_return(nil)
        
        service = described_class.new(
          mail: mail, parsed_mail: parsed_mail, account: account,
          inbox: inbox, sender: sender, conversation: conversation
        )
        
        message = service.call
        expect(message.content).to match(/<img src="http.*test.png".*>/)
        expect(message.content).not_to include('[image: test.png]')
      end
    end
  end
end

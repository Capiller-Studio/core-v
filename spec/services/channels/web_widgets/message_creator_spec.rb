require 'rails_helper'

RSpec.describe Channels::WebWidgets::MessageCreator do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:sender) { create(:customer, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:attachments) { [] }
  let(:service) do
    described_class.new(
      account: account, inbox: inbox, conversation: conversation, sender: sender, content: 'Hello Web Widget', attachments: attachments
    )
  end
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'without attachments' do
      it 'creates a text message' do
        expect { service.call }.to change(Message, :count).by(1)
        
        message = service.message
        expect(message.content).to eq('Hello Web Widget')
        expect(message.source).to eq('web_widget')
        expect(message.account).to eq(account)
        expect(message.sender).to eq(sender)
        expect(message.conversation).to eq(conversation)
        expect(message.attachments.count).to eq(0)
      end
    end

    context 'with attachments' do
      let(:file1) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.png'), 'image/png') }
      let(:file2) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.pdf'), 'application/pdf') }
      let(:attachments) { [file1, file2] }

      before do
        # Create mock files since we might not have them in spec/fixtures
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        File.write(Rails.root.join('spec/fixtures/files/test.png'), 'fake image')
        File.write(Rails.root.join('spec/fixtures/files/test.pdf'), 'fake pdf')
      end

      it 'creates message and attaches files' do
        expect { service.call }.to change(Message, :count).by(1)
                               .and change(Attachment, :count).by(2)
                               .and change(ActiveStorage::Attachment, :count).by(2)
        
        message = service.message
        expect(message.attachments.count).to eq(2)
        
        image_attachment = message.attachments.find_by(attachment_type: :image)
        expect(image_attachment).to be_present
        expect(image_attachment.file).to be_attached
        expect(image_attachment.file.content_type).to eq('image/png')

        pdf_attachment = message.attachments.find_by(attachment_type: :file)
        expect(pdf_attachment).to be_present
        expect(pdf_attachment.file).to be_attached
        expect(pdf_attachment.file.content_type).to eq('application/pdf')
      end
    end

    context 'when an error occurs during attachment' do
      let(:file1) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.png'), 'image/png') }
      let(:attachments) { [file1] }

      before do
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        File.write(Rails.root.join('spec/fixtures/files/test.png'), 'fake image')
        
        allow_any_instance_of(Attachment).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Attachment.new))
      end

      it 'rolls back message creation' do
        expect {
          begin
            service.call
          rescue ActiveRecord::RecordInvalid
          end
        }.to change(Message, :count).by(0).and change(Attachment, :count).by(0)
      end
    end
  end
end

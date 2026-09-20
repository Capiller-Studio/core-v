# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::ContactForms::MessageCreator, type: :service do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_contact_form, account: account) }
  let(:inbox) { create(:inbox, channel: channel, account: account, primary_inbox: true) }
  let(:customer) { create(:customer, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, source: :help_center) }

  let(:image_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new('fake-png-content'),
      'image/png',
      original_filename: 'screenshot.png'
    )
  end

  let(:pdf_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new('fake-pdf-content'),
      'application/pdf',
      original_filename: 'document.pdf'
    )
  end

  let(:video_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new('fake-mp4-content'),
      'video/mp4',
      original_filename: 'screen-recording.mp4'
    )
  end

  let(:audio_file) do
    Rack::Test::UploadedFile.new(
      StringIO.new('fake-audio-content'),
      'audio/mpeg',
      original_filename: 'voice-note.mp3'
    )
  end

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe '#call' do
    it 'creates a real Message record in database with source :help_center' do
      service = described_class.new(
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: customer,
        content: 'I need help with my subscription.',
        attachments: []
      )

      expect {
        message = service.call
        expect(message).to be_persisted
        expect(message.account).to eq(account)
        expect(message.inbox).to eq(inbox)
        expect(message.conversation).to eq(conversation)
        expect(message.sender).to eq(customer)
        expect(message.content).to eq('I need help with my subscription.')
        expect(message.source).to eq('help_center')
        expect(message.incoming?).to be(true)
      }.to change(conversation.messages, :count).by(1)
    end

    it 'handles nil attachments gracefully' do
      service = described_class.new(
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: customer,
        content: 'No attachments here',
        attachments: nil
      )

      message = service.call
      expect(message).to be_persisted
      expect(message.attachments).to be_empty
    end

    context 'with multiple attachments of various types' do
      it 'creates real Attachment records with correct attachment_type and attaches files' do
        service = described_class.new(
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: customer,
          content: 'Here are the diagnostic files',
          attachments: [image_file, pdf_file, video_file, audio_file]
        )

        message = nil
        expect {
          message = service.call
        }.to change(Attachment, :count).by(4)

        expect(message.attachments.count).to eq(4)

        attachments_by_type = message.attachments.index_by(&:attachment_type)
        expect(attachments_by_type.keys).to contain_exactly('image', 'file', 'video', 'audio')

        image_att = attachments_by_type['image']
        expect(image_att.file).to be_attached
        expect(image_att.file.filename.to_s).to eq('screenshot.png')

        pdf_att = attachments_by_type['file']
        expect(pdf_att.file).to be_attached
        expect(pdf_att.file.filename.to_s).to eq('document.pdf')

        video_att = attachments_by_type['video']
        expect(video_att.file).to be_attached
        expect(video_att.file.filename.to_s).to eq('screen-recording.mp4')

        audio_att = attachments_by_type['audio']
        expect(audio_att.file).to be_attached
        expect(audio_att.file.filename.to_s).to eq('voice-note.mp3')
      end
    end
  end
end

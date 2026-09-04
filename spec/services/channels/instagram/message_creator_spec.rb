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
    allow(messages_assoc).to receive(:find_by).and_return(nil)
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

    it 'returns existing message if already present' do
      existing_message = double('Message')
      allow(messages_assoc).to receive(:find_by).with(external_id: 'ig_mid_123').and_return(existing_message)

      expect(messages_assoc).not_to receive(:create!)
      expect(service.call).to eq(existing_message)
    end

    context 'with unsupported attachments and no content' do
      let(:parsed_message) do
        double('ParsedMessage',
          mid: 'ig_mid_unsupported',
          reply_to_mid: nil,
          content: '',
          attachments: [{ "type" => "animated_sticker" }],
          message: nil
        )
      end

      it 'returns nil without creating message when all attachments are unsupported' do
        expect(messages_assoc).not_to receive(:create!)
        expect(service.call).to be_nil
      end
    end

    context 'with mixed attachments (one unsupported and one supported)' do
      let(:attachments) do
        [
          { "type" => "animated_sticker" },
          { "type" => "image", "payload" => { "url" => "http://test.com/photo.jpg" } }
        ]
      end
      let(:parsed_message) do
        double('ParsedMessage',
          mid: 'ig_mid_mixed',
          reply_to_mid: nil,
          content: '',
          attachments: attachments,
          message: nil
        )
      end
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:tempfile) { double('Tempfile', original_filename: 'photo.jpg', content_type: 'image/jpeg') }
      let(:attachment_record) { double('AttachmentRecord', remote_url: "http://test.com/photo.jpg", attachment_type: 'image', file: active_storage_file) }
      let(:active_storage_file) { double('ActiveStorageFile') }

      before do
        allow(messages_assoc).to receive(:find_by).with(external_id: 'ig_mid_mixed').and_return(nil)
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).with("http://test.com/photo.jpg").and_return(tempfile)
        allow(active_storage_file).to receive(:attach)
        stub_const('Utilities::AttachmentTypeHelpers', double('Helpers'))
        allow(Utilities::AttachmentTypeHelpers).to receive(:attachment_type).and_return('image')
      end

      it 'creates message and processes only the supported attachment' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(remote_url: "http://test.com/photo.jpg", attachment_type: 'image')
        ).and_return(attachment_record)

        expect(active_storage_file).to receive(:attach).with(
          hash_including(io: tempfile, filename: 'photo.jpg', content_type: 'image/jpeg')
        )

        expect(service.call).to eq(message)
      end
    end

    context 'with location attachment' do
      let(:attachments) do
        [
          {
            "type" => "location",
            "url" => "https://maps.google.com/?q=40.7128,-74.0060",
            "title" => "New York",
            "payload" => {
              "coordinates" => { "lat" => 40.7128, "long" => -74.0060 }
            }
          }
        ]
      end
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:location_record) { double('LocationRecord', remote_url: "https://maps.google.com/?q=40.7128,-74.0060") }

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).and_return(nil)
      end

      it 'processes location attachment with coordinates and alt_title' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(
            remote_url: "https://maps.google.com/?q=40.7128,-74.0060",
            latitude: 40.7128,
            longitude: -74.0060,
            alt_title: "New York",
            attachment_type: "location"
          )
        ).and_return(location_record)

        expect { service.call }.not_to raise_error
      end
    end

    context 'with fallback attachment' do
      let(:attachments) do
        [
          {
            "type" => "fallback",
            "url" => "https://instagram.com/p/123",
            "title" => "Instagram Post"
          }
        ]
      end
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:fallback_record) { double('FallbackRecord', remote_url: "https://instagram.com/p/123") }

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).and_return(nil)
      end

      it 'processes fallback attachment' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(
            remote_url: "https://instagram.com/p/123",
            alt_title: "Instagram Post",
            attachment_type: "fallback"
          )
        ).and_return(fallback_record)

        expect { service.call }.not_to raise_error
      end
    end

    context 'with story mention attachment' do
      let(:attachments) { [{ "type" => "story_mention", "payload" => { "url" => "http://test.com/story.mp4" } }] }
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:tempfile) { double('Tempfile', original_filename: 'story.mp4', content_type: 'video/mp4') }
      let(:attachment_record) do
        double('AttachmentRecord',
               remote_url: "http://test.com/story.mp4",
               attachment_type: 'story_mention',
               file: double('ActiveStorageFile', attach: nil))
      end
      let(:story_response) do
        double('HTTParty::Response',
               success?: true,
               body: {
                 "story" => { "mention" => { "id" => "mention_ig_1" } },
                 "from" => { "username" => "ig_user" }
               }.to_json)
      end

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).with("http://test.com/story.mp4").and_return(tempfile)
        stub_const('Utilities::AttachmentTypeHelpers', double('Helpers'))
        allow(Utilities::AttachmentTypeHelpers).to receive(:attachment_type).and_return('story_mention')
      end

      it 'fetches story details from Instagram Graph API and updates attachment' do
        expect(HTTParty).to receive(:get).with(
          "https://graph.instagram.com/v26.0/ig_mid_123",
          hash_including(query: hash_including(access_token: 'token'))
        ).and_return(story_response)

        expect(message_attachments_assoc).to receive(:create!).and_return(attachment_record)
        expect(attachment_record).to receive(:update).with(
          data: {
            story_mention_id: "mention_ig_1",
            story_username: "ig_user"
          }
        )

        service.call
      end
    end

    context 'when attachment download fails' do
      let(:attachments) { [{ "type" => "image", "payload" => { "url" => "http://test.com/photo.jpg" } }] }
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:attachment_record) { double('AttachmentRecord', remote_url: "http://test.com/photo.jpg", attachment_type: 'image', file: active_storage_file) }
      let(:active_storage_file) { double('ActiveStorageFile') }

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).with("http://test.com/photo.jpg").and_raise(StandardError.new("Connection refused"))
        stub_const('Utilities::AttachmentTypeHelpers', double('Helpers'))
      end

      it 'logs download failure and continues without crashing' do
        expect(Rails.logger).to receive(:error).with(/Failed to download file from/)
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(remote_url: "http://test.com/photo.jpg", attachment_type: 'image')
        ).and_return(attachment_record)

        expect { service.call }.not_to raise_error
      end
    end
  end
end

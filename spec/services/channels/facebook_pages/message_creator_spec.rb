require 'rails_helper'

RSpec.describe Channels::FacebookPages::MessageCreator do
  let(:account) { double('Account') }
  let(:inbox) { double('Inbox') }
  let(:sender) { double('Customer') }
  let(:conversation) { double('Conversation', messages: messages_assoc) }
  let(:messages_assoc) { double('MessagesAssoc') }
  let(:facebook_page_channel) { double('FacebookPageChannel', access_token: 'token') }
  
  let(:parsed_message) do 
    double('ParsedMessage', 
      mid: 'fb_mid_123', 
      reply_to_mid: 'fb_mid_0', 
      content: 'Hello',
      attachments: attachments
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
      facebook_page_channel: facebook_page_channel
    )
  end

  before do
    allow(messages_assoc).to receive(:find_by).with(external_id: 'fb_mid_123').and_return(nil)
  end

  describe '#call' do
    it 'creates a message if it does not exist' do
      message = double('Message', attachments: [])
      expect(messages_assoc).to receive(:create!).with(
        hash_including(
          account: account,
          sender: sender,
          content: 'Hello',
          inbox: inbox,
          external_id: 'fb_mid_123',
          external_reply_to_id: 'fb_mid_0'
        )
      ).and_return(message)

      expect(service.call).to eq(message)
    end

    it 'returns existing message if it exists' do
      existing_message = double('Message')
      allow(messages_assoc).to receive(:find_by).with(external_id: 'fb_mid_123').and_return(existing_message)
      
      expect(messages_assoc).not_to receive(:create!)
      expect(service.call).to eq(existing_message)
    end

    context 'with attachments' do
      let(:attachments) { [{ "type" => "image", "payload" => { "url" => "http://test.com/img.png" } }] }
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:tempfile) { double('Tempfile', original_filename: 'img.png', content_type: 'image/png') }
      let(:attachment_record) { double('AttachmentRecord', remote_url: "http://test.com/img.png", attachment_type: 'image', file: active_storage_file) }
      let(:active_storage_file) { double('ActiveStorageFile') }

      before do
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).with("http://test.com/img.png").and_return(tempfile)
        allow(messages_assoc).to receive(:create!).and_return(message)
        
        stub_const('Utilities::AttachmentTypeHelpers', double('Helpers'))
        allow(Utilities::AttachmentTypeHelpers).to receive(:attachment_type).and_return('image')
      end

      it 'downloads and processes file attachments' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(remote_url: "http://test.com/img.png", attachment_type: 'image')
        ).and_return(attachment_record)

        expect(active_storage_file).to receive(:attach).with(
          hash_including(io: tempfile, filename: 'img.png', content_type: 'image/png')
        )

        service.call
      end

      it 'handles download failure gracefully without crashing' do
        allow(Down).to receive(:download).with("http://test.com/img.png").and_raise(StandardError.new("Network failure"))
        expect(Rails.logger).to receive(:error).with(/Failed to download file/)

        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(remote_url: "http://test.com/img.png", attachment_type: 'image')
        ).and_return(attachment_record)

        expect { service.call }.not_to raise_error
      end
    end

    context 'with location attachment' do
      let(:attachments) do
        [
          {
            "type" => "location",
            "url" => "https://maps.google.com/?q=37.4219999,-122.0840575",
            "title" => "Googleplex",
            "payload" => {
              "coordinates" => {
                "lat" => 37.4219999,
                "long" => -122.0840575
              }
            }
          }
        ]
      end
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:location_record) { double('LocationRecord', remote_url: "https://maps.google.com/?q=37.4219999,-122.0840575") }

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).and_return(nil)
      end

      it 'processes location attachment with coordinates and alt_title without ArgumentError' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(
            remote_url: "https://maps.google.com/?q=37.4219999,-122.0840575",
            latitude: 37.4219999,
            longitude: -122.0840575,
            alt_title: "Googleplex",
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
            "url" => "https://example.com/item",
            "title" => "Shared Link"
          }
        ]
      end
      let(:message) { double('Message', attachments: message_attachments_assoc) }
      let(:message_attachments_assoc) { double('MessageAttachmentsAssoc') }
      let(:fallback_record) { double('FallbackRecord', remote_url: "https://example.com/item") }

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).and_return(nil)
      end

      it 'processes fallback attachment with alt_title without ArgumentError' do
        expect(message_attachments_assoc).to receive(:create!).with(
          hash_including(
            remote_url: "https://example.com/item",
            alt_title: "Shared Link",
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
      let(:koala_client) { instance_double(Koala::Facebook::API) }

      before do
        allow(messages_assoc).to receive(:create!).and_return(message)
        stub_const('Down', double('Down'))
        allow(Down).to receive(:download).with("http://test.com/story.mp4").and_return(tempfile)
        stub_const('Utilities::AttachmentTypeHelpers', double('Helpers'))
        allow(Utilities::AttachmentTypeHelpers).to receive(:attachment_type).and_return('story_mention')
        allow(Koala::Facebook::API).to receive(:new).with('token').and_return(koala_client)
      end

      it 'fetches story using message mid and handles story mention' do
        expect(message_attachments_assoc).to receive(:create!).and_return(attachment_record)
        expect(koala_client).to receive(:get_object).with('fb_mid_123', fields: %w[story from]).and_return({
          "story" => { "mention" => { "id" => "mention_123" } },
          "from" => { "username" => "john_doe" }
        })

        expect { service.call }.not_to raise_error
      end

      it 'handles authentication error during story fetch gracefully' do
        expect(message_attachments_assoc).to receive(:create!).and_return(attachment_record)
        expect(koala_client).to receive(:get_object).with('fb_mid_123', fields: %w[story from]).and_raise(
          Koala::Facebook::AuthenticationError.new(401, 'Token expired')
        )
        expect(facebook_page_channel).to receive(:authorization_error!)

        expect { service.call }.not_to raise_error
      end
    end
  end
end

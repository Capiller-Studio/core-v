# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::MessageSender do
  let(:whatsapp_channel) do
    double(
      'Channel::Whatsapp',
      phone_number_endpoint: 'https://api.whatsapp/123',
      api_headers: { 'Authorization' => 'Bearer token_123' },
      phone_number_id: '123',
      full_phone_number: '+123',
      template_name: nil,
      template_language: 'en_US'
    )
  end
  let(:customer) { double('Customer', full_phone_number: '+15551234567', external_id: '15551234567') }
  let(:customer_inbox) { double('CustomerInbox', customer: customer, external_id: '15551234567') }
  let(:message) { double('Message', id: 'msg_uuid_1', content: 'Hello', attachments: [], external_reply_to_id: nil, data: {}, conversation: nil) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, customer_inbox: customer_inbox, message: message) }

  before do
    allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Hello').and_return('Hello Markdown')
  end

  describe '#call' do
    it 'sends text message via HTTParty with sanitized recipient digits' do
      response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_msg_1" }] })

      expected_body = {
        messaging_product: "whatsapp",
        context: nil,
        to: '15551234567',
        text: { body: 'Hello Markdown' },
        type: "text"
      }.to_json

      expect(HTTParty).to receive(:post).with(
        "https://api.whatsapp/123/messages",
        headers: { 'Authorization' => 'Bearer token_123' },
        body: expected_body
      ).and_return(response)

      expect(message).to receive(:update!).with(external_id: "wa_msg_1")

      service.call
    end

    context 'when recipient phone number is missing' do
      let(:empty_customer) { double('Customer', full_phone_number: nil, external_id: nil) }
      let(:customer_inbox) { double('CustomerInbox', customer: empty_customer, external_id: nil) }

      it 'marks message as failed without calling HTTParty' do
        expect(HTTParty).not_to receive(:post)
        expect(message).to receive(:update!).with(
          status: :failed,
          data: { "error_message" => "Recipient phone number is missing" }
        )
        expect(Rails.logger).to receive(:warn).with(/Recipient phone number is missing/)

        service.call
      end
    end

    context 'when recipient phone number has special formatting' do
      let(:customer) { double('Customer', full_phone_number: '+1 (555) 019-2831', external_id: nil) }

      it 'normalizes recipient phone number to pure digits' do
        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_msg_norm" }] })

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: anything,
          body: a_string_matching(/"to":"15550192831"/)
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_msg_norm")

        service.call
      end
    end

    context 'when message content is blank and no attachments exist' do
      let(:message) { double('Message', id: 'msg_uuid_empty', content: '', attachments: [], external_reply_to_id: nil, data: {}, conversation: nil) }

      it 'does not make any HTTP calls' do
        expect(HTTParty).not_to receive(:post)
        service.call
      end
    end

    context 'with attachments' do
      let(:file) { double('File', filename: 'doc.pdf') }
      let(:attachment) { double('Attachment', id: 'att_1', attachment_type: 'document', direct_download_url: 'http://doc.url', file: file) }
      let(:message) { double('Message', id: 'msg_uuid_doc', content: 'Here is doc', attachments: [attachment], external_reply_to_id: 'wa_parent_1', data: {}, conversation: nil) }

      it 'sends document attachment message with caption and filename' do
        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_msg_2" }] })

        allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Here is doc').and_return('Here is doc')

        expected_body = {
          messaging_product: "whatsapp",
          context: { message_id: 'wa_parent_1' },
          to: '15551234567',
          type: "document",
          "document" => { link: 'http://doc.url', "caption" => 'Here is doc', "filename" => 'doc.pdf' }
        }.to_json

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: { 'Authorization' => 'Bearer token_123' },
          body: expected_body
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_msg_2")

        service.call
      end

      context 'with single video attachment and caption' do
        let(:video_attachment) { double('Attachment', id: 'att_video', attachment_type: 'video', direct_download_url: 'http://video.url', file: nil) }
        let(:message) { double('Message', id: 'msg_uuid_vid', content: 'Watch this', attachments: [video_attachment], external_reply_to_id: nil, data: {}, conversation: nil) }

        it 'sends video message with caption' do
          allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Watch this').and_return('Watch this')
          response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_video_msg" }] })

          expected_body = {
            messaging_product: "whatsapp",
            context: nil,
            to: '15551234567',
            type: "video",
            "video" => { link: 'http://video.url', "caption" => 'Watch this' }
          }.to_json

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: expected_body
          ).and_return(response)

          expect(message).to receive(:update!).with(external_id: "wa_video_msg")

          service.call
        end
      end

      context 'with single image attachment without caption' do
        let(:image_attachment) { double('Attachment', id: 'att_img', attachment_type: 'image', direct_download_url: 'http://img.url', file: nil) }
        let(:message) { double('Message', id: 'msg_uuid_img', content: nil, attachments: [image_attachment], external_reply_to_id: nil, data: {}, conversation: nil) }

        it 'sends image message without caption field' do
          response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_img_msg" }] })

          expected_body = {
            messaging_product: "whatsapp",
            context: nil,
            to: '15551234567',
            type: "image",
            "image" => { link: 'http://img.url' }
          }.to_json

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: expected_body
          ).and_return(response)

          expect(message).to receive(:update!).with(external_id: "wa_img_msg")

          service.call
        end
      end

      context 'when attachment has nil direct_download_url' do
        let(:bad_attachment) { double('Attachment', id: 'att_broken', attachment_type: 'image', direct_download_url: nil, file: nil) }
        let(:message) { double('Message', id: 'msg_uuid_bad', content: 'Image here', attachments: [bad_attachment], external_reply_to_id: nil, data: {}, conversation: nil) }

        it 'marks message failed without calling HTTParty' do
          expect(HTTParty).not_to receive(:post)
          expect(message).to receive(:update!).with(
            status: :failed,
            data: { "error_message" => "Attachment file URL is missing" }
          )

          service.call
        end
      end

      context 'with document attachment without file object' do
        let(:doc_no_file) { double('Attachment', id: 'att_no_file', attachment_type: 'document', direct_download_url: 'http://doc.url', file: nil) }
        let(:message) { double('Message', id: 'msg_uuid_doc_nf', content: nil, attachments: [doc_no_file], external_reply_to_id: nil, data: {}, conversation: nil) }

        it 'sends document without crashing on filename' do
          response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_doc_nf" }] })

          expected_body = {
            messaging_product: "whatsapp",
            context: nil,
            to: '15551234567',
            type: "document",
            "document" => { link: 'http://doc.url' }
          }.to_json

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: expected_body
          ).and_return(response)

          expect(message).to receive(:update!).with(external_id: "wa_doc_nf")

          service.call
        end
      end

      context 'with multiple attachments' do
        let(:file2) { double('File', filename: 'image.jpg') }
        let(:attachment2) { double('Attachment', id: 'att_2', attachment_type: 'image', direct_download_url: 'http://img.url', file: file2) }
        let(:message) { double('Message', id: 'msg_uuid_multi', content: 'Here are files', attachments: [attachment, attachment2], external_reply_to_id: nil, data: {}, conversation: nil) }

        it 'sends text message first then every attachment individually' do
          allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Here are files').and_return('Here are files')
          text_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_text_id" }] })
          att1_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_att1_id" }] })
          att2_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_att2_id" }] })

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"text"/)
          ).and_return(text_response).ordered

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"document"/)
          ).and_return(att1_response).ordered

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"image"/)
          ).and_return(att2_response).ordered

          expect(message).to receive(:update!).with(external_id: "wa_text_id")
          expect(message).to receive(:update!).with(external_id: "wa_att1_id")
          expect(message).to receive(:update!).with(external_id: "wa_att2_id")

          service.call
        end
      end

      context 'with non-captionable attachment (audio) and text content' do
        let(:audio_file) { double('File', filename: 'voice.ogg') }
        let(:audio_attachment) { double('Attachment', id: 'att_audio', attachment_type: 'audio', direct_download_url: 'http://audio.url', file: audio_file) }
        let(:message) { double('Message', id: 'msg_uuid_audio', content: 'Listen to this voice note', attachments: [audio_attachment], external_reply_to_id: nil, data: {}, conversation: nil) }

        it 'sends text message and then audio attachment separately without caption' do
          allow(Channels::MessageFormatter).to receive(:format_for_whatsapp_and_facebook).with('Listen to this voice note').and_return('Listen to this voice note')
          text_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_text_id" }] })
          audio_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_audio_id" }] })

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"text"/)
          ).and_return(text_response).ordered

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"audio"/)
          ).and_return(audio_response).ordered

          expect(message).to receive(:update!).with(external_id: "wa_text_id")
          expect(message).to receive(:update!).with(external_id: "wa_audio_id")

          service.call
        end

        it 'sends audio attachment as document when format is wav to avoid Meta API errors' do
          wav_file = double('File', filename: 'voice.wav')
          wav_att = double('Attachment', id: 'att_wav', attachment_type: 'audio', direct_download_url: 'http://audio.url/voice.wav', file: wav_file)
          wav_msg = double('Message', id: 'msg_wav', content: nil, attachments: [wav_att], external_reply_to_id: nil, data: {}, conversation: nil)
          wav_svc = described_class.new(whatsapp_channel: whatsapp_channel, customer_inbox: customer_inbox, message: wav_msg)

          audio_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_wav_id" }] })

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"document"/)
          ).and_return(audio_response)

          expect(wav_msg).to receive(:update!).with(external_id: "wa_wav_id")

          wav_svc.call
        end

        it 'keeps file attachment type as document even if file has audio extension' do
          audio_file_att = double('File', filename: 'podcast.mp3')
          file_att = double('Attachment', id: 'att_file_mp3', attachment_type: 'file', direct_download_url: 'http://doc.url/podcast.mp3', file: audio_file_att)
          file_msg = double('Message', id: 'msg_file_mp3', content: nil, attachments: [file_att], external_reply_to_id: nil, data: {}, conversation: nil)
          file_svc = described_class.new(whatsapp_channel: whatsapp_channel, customer_inbox: customer_inbox, message: file_msg)

          doc_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_doc_mp3_id" }] })

          expect(HTTParty).to receive(:post).with(
            "https://api.whatsapp/123/messages",
            headers: anything,
            body: a_string_matching(/"type":"document"/)
          ).and_return(doc_response)

          expect(file_msg).to receive(:update!).with(external_id: "wa_doc_mp3_id")

          file_svc.call
        end
      end
    end

    context 'when outside 24 hour window' do
      let(:conversation) { double('Conversation', locale: 'en') }
      let(:messages_relation) { double('MessagesRelation') }
      let(:ordered_relation) { double('OrderedRelation') }

      before do
        allow(message).to receive(:conversation).and_return(conversation)
        allow(conversation).to receive(:messages).and_return(messages_relation)
        allow(messages_relation).to receive(:where).with(sender_type: 'Customer').and_return(ordered_relation)
        allow(ordered_relation).to receive(:order).with(created_at: :desc).and_return(ordered_relation)
        allow(ordered_relation).to receive(:pick).with(:created_at).and_return(25.hours.ago)
      end

      it 'sends template message when template is configured' do
        allow(whatsapp_channel).to receive(:template_name).and_return('customer_update')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')

        expected_body = {
          messaging_product: "whatsapp",
          to: '15551234567',
          type: "template",
          template: {
            name: 'customer_update',
            language: { code: 'en_US' },
            components: [
              {
                type: 'body',
                parameters: [{ type: 'text', text: 'Hello Markdown' }]
              }
            ]
          }
        }.to_json

        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_1" }] })

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: anything,
          body: expected_body
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_tpl_1")

        service.call
      end

      it 'supports custom template parameters as an array of strings, numbers, and hashes' do
        allow(whatsapp_channel).to receive(:template_name).and_return('order_status')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')
        allow(message).to receive(:data).and_return({
          'template_parameters' => ['John Doe', 12345, { type: 'text', text: 'Shipped' }]
        })

        expected_body = {
          messaging_product: "whatsapp",
          to: '15551234567',
          type: "template",
          template: {
            name: 'order_status',
            language: { code: 'en_US' },
            components: [
              {
                type: 'body',
                parameters: [
                  { type: 'text', text: 'John Doe' },
                  { type: 'text', text: '12345' },
                  { type: 'text', text: 'Shipped' }
                ]
              }
            ]
          }
        }.to_json

        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_params" }] })

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: anything,
          body: expected_body
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_tpl_params")

        service.call
      end

      it 'uses explicit pre-defined template_components when present in message.data' do
        allow(whatsapp_channel).to receive(:template_name).and_return('custom_comp')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')
        custom_components = [
          { type: 'header', parameters: [{ type: 'text', text: 'Header Title' }] },
          { type: 'button', sub_type: 'quick_reply', index: 0, parameters: [{ type: 'payload', payload: 'YES' }] }
        ]
        allow(message).to receive(:data).and_return({ 'template_components' => custom_components })

        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_custom" }] })

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: anything,
          body: a_string_matching(/"sub_type":"quick_reply"/)
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_tpl_custom")

        service.call
      end

      it 'adds image media header component for template when image attachment is present' do
        allow(whatsapp_channel).to receive(:template_name).and_return('promo_image')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')
        img_attachment = double('Attachment', id: 'img_head', attachment_type: 'image', direct_download_url: 'http://img.url/head.png', file: nil)
        allow(message).to receive(:attachments).and_return([img_attachment])

        expected_body = {
          messaging_product: "whatsapp",
          to: '15551234567',
          type: "template",
          template: {
            name: 'promo_image',
            language: { code: 'en_US' },
            components: [
              {
                type: 'header',
                parameters: [{ type: 'image', 'image' => { link: 'http://img.url/head.png' } }]
              },
              {
                type: 'body',
                parameters: [{ type: 'text', text: 'Hello Markdown' }]
              }
            ]
          }
        }.to_json

        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_head" }] })

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: anything,
          body: expected_body
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_tpl_head")

        service.call
      end

      it 'skips media header component when attachment is audio (not supported by Meta as template header)' do
        allow(whatsapp_channel).to receive(:template_name).and_return('voice_update')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')
        audio_att = double('Attachment', id: 'aud_head', attachment_type: 'audio', direct_download_url: 'http://aud.url/note.ogg', file: nil)
        allow(message).to receive(:attachments).and_return([audio_att])

        response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_no_audio_head" }] })

        expect(HTTParty).to receive(:post).with(
          "https://api.whatsapp/123/messages",
          headers: anything,
          body: satisfy { |b| b.exclude?('"type":"header"') }
        ).and_return(response)

        expect(message).to receive(:update!).with(external_id: "wa_tpl_no_audio_head")

        service.call
      end
    end

    context 'with locale normalizations' do
      it 'normalizes various locale inputs to Meta Cloud API format' do
        expect(service.send(:normalize_meta_locale, 'en')).to eq('en_US')
        expect(service.send(:normalize_meta_locale, 'en-us')).to eq('en_US')
        expect(service.send(:normalize_meta_locale, 'en-gb')).to eq('en_GB')
        expect(service.send(:normalize_meta_locale, 'pt')).to eq('pt_BR')
        expect(service.send(:normalize_meta_locale, 'pt-br')).to eq('pt_BR')
        expect(service.send(:normalize_meta_locale, 'es')).to eq('es')
        expect(service.send(:normalize_meta_locale, 'es-es')).to eq('es_ES')
        expect(service.send(:normalize_meta_locale, 'zh')).to eq('zh_CN')
        expect(service.send(:normalize_meta_locale, 'ar')).to eq('ar')
        expect(service.send(:normalize_meta_locale, nil)).to eq('en_US')
      end
    end

    context 'when an error occurs' do
      it 'handles 24h customer service window expired error 131047 without configured template' do
        allow(whatsapp_channel).to receive(:template_name).and_return(nil)

        err_body = {
          "error" => {
            "message" => "(#131047) Message failed to send because more than 24 hours have passed",
            "code" => 131047
          }
        }
        response = double('Response', success?: false, unauthorized?: false, code: 400, parsed_response: err_body)

        expect(HTTParty).to receive(:post).and_return(response)
        expect(message).to receive(:update!).with(
          status: :failed,
          data: {
            "error_code" => 131047,
            "error_message" => "(#131047) Message failed to send because more than 24 hours have passed"
          }
        )
        expect(Rails.logger).to receive(:warn).with(/WhatsApp 24-hour customer service window closed/)

        service.call
      end

      it 'automatically retries with template if error 131047 occurs and template is configured' do
        allow(whatsapp_channel).to receive(:template_name).and_return('customer_update')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')

        err_body = {
          "error" => {
            "message" => "(#131047) Message failed to send because more than 24 hours have passed",
            "code" => 131047
          }
        }
        err_response = double('Response', success?: false, unauthorized?: false, code: 400, parsed_response: err_body)
        success_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_retry" }] })

        expect(HTTParty).to receive(:post).and_return(err_response).ordered
        expect(HTTParty).to receive(:post).and_return(success_response).ordered

        expect(message).to receive(:update!).with(external_id: "wa_tpl_retry")

        service.call
      end

      it 'automatically retries with default language if error 132000 language mismatch occurs' do
        allow(whatsapp_channel).to receive(:template_name).and_return('customer_update')
        allow(whatsapp_channel).to receive(:template_language).and_return('en_US')
        allow(message).to receive(:data).and_return({ 'template_language' => 'fr' })

        err_body = {
          "error" => {
            "message" => "(#132000) The language fr does not match the template language en_US",
            "code" => 132000
          }
        }
        err_response = double('Response', success?: false, unauthorized?: false, code: 400, parsed_response: err_body)
        success_response = double('Response', success?: true, parsed_response: { "messages" => [{ "id" => "wa_tpl_lang_retry" }] })

        expect(HTTParty).to receive(:post).and_return(err_response).ordered
        expect(HTTParty).to receive(:post).and_return(success_response).ordered

        expect(message).to receive(:update!).with(external_id: "wa_tpl_lang_retry")

        service.call
      end

      it 'triggers whatsapp_channel.authorization_error! on 401 Unauthorized response' do
        err_body = {
          "error" => {
            "message" => "Error validating access token: Session has expired",
            "type" => "OAuthException",
            "code" => 190
          }
        }
        response = double('Response', success?: false, unauthorized?: true, code: 401, parsed_response: err_body)

        expect(HTTParty).to receive(:post).and_return(response)
        expect(whatsapp_channel).to receive(:authorization_error!)
        expect(message).to receive(:update!).with(
          status: :failed,
          data: {
            "error_code" => 190,
            "error_message" => "Error validating access token: Session has expired"
          }
        )

        service.call
      end

      it 'raises transient error when Meta returns HTTP 429 rate limit so Sidekiq retries' do
        err_body = {
          "error" => {
            "message" => "(#130429) Rate limit hit",
            "code" => 130429
          }
        }
        response = double('Response', success?: false, unauthorized?: false, code: 429, parsed_response: err_body)

        expect(HTTParty).to receive(:post).and_return(response)
        expect(message).not_to receive(:update!).with(status: :failed)

        expect { service.call }.to raise_error(/Meta WhatsApp API transient error/)
      end

      it 'raises transient error when Meta returns HTTP 500, 502, 503, or 504' do
        response = double('Response', success?: false, unauthorized?: false, code: 502, parsed_response: 'Bad Gateway')

        expect(HTTParty).to receive(:post).and_return(response)
        expect(message).not_to receive(:update!).with(status: :failed)

        expect { service.call }.to raise_error(/Meta WhatsApp API transient error \(502\)/)
      end

      it 'raises transient error when Meta returns transient error codes 1, 2, or 4' do
        [1, 2, 4].each do |code|
          err_body = { "error" => { "message" => "Service temporary glitch", "code" => code } }
          response = double('Response', success?: false, unauthorized?: false, code: 400, parsed_response: err_body)

          expect(HTTParty).to receive(:post).and_return(response)
          expect { service.call }.to raise_error(/Meta WhatsApp API transient error/)
        end
      end

      it 'handles upstream HTML or non-JSON error string responses without raising TypeError' do
        response = double('Response', success?: false, unauthorized?: false, code: 400, parsed_response: '<html>Service Unavailable</html>')

        expect(HTTParty).to receive(:post).and_return(response)
        expect(message).to receive(:update!).with(
          status: :failed,
          data: {
            "error_code" => nil,
            "error_message" => "<html>Service Unavailable</html>"
          }
        )

        expect { service.call }.not_to raise_error
      end

      it 're-raises network timeouts for Sidekiq retry' do
        expect(HTTParty).to receive(:post).and_raise(Net::ReadTimeout.new("Read timeout"))
        expect { service.call }.to raise_error(Net::ReadTimeout)
      end

      it 're-raises connection reset errors for Sidekiq retry' do
        expect(HTTParty).to receive(:post).and_raise(Errno::ECONNRESET.new("Connection reset"))
        expect { service.call }.to raise_error(Errno::ECONNRESET)
      end

      it 'marks message failed and flags authorization_error! when rescued error mentions OAuthException' do
        expect(HTTParty).to receive(:post).and_raise(StandardError.new("OAuthException: Token expired"))
        expect(whatsapp_channel).to receive(:authorization_error!)
        expect(message).to receive(:update!).with(
          status: :failed,
          data: { "error_message" => "OAuthException: Token expired" }
        )

        service.call
      end
    end
  end
end

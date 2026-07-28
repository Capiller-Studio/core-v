require 'rails_helper'

RSpec.describe Channels::ServicePicker do
  let(:inbox) { double('Inbox', channel: default_channel, id: 1) }
  let(:customer_inbox) { double('CustomerInbox', inbox_id: 1) }
  let(:conversation) { double('Conversation', inbox: inbox, outbound_channel: nil, customer_inboxes: [customer_inbox]) }
  let(:message) { double('Message', outgoing?: true, outbound_channel: nil, account_id: 2, id: 10) }
  
  before do
    allow(message).to receive(:update).with(outbound_channel: anything)
  end

  describe '#call' do
    context 'with Email channel' do
      let(:default_channel) { double('Channel::Email', class: double(name: 'Channel::Email')) }
      let(:service) { described_class.new(conversation: conversation, message: message) }

      before do
        stub_const('ConversationReplyMailer', double('Mailer'))
      end

      it 'calls channel_email_service' do
        mail_message = double('MailMessage', message_id: 'msg_123')
        mailer = double('Reply')
        expect(ConversationReplyMailer).to receive(:reply).with(conversation, message).and_return(mailer)
        expect(mailer).to receive(:deliver_now).and_return(mail_message)

        expect(message).to receive(:update_columns).with(external_id: 'msg_123', status: :delivered)

        service.call
      end

      it 'handles delivery errors' do
        mailer = double('Reply')
        expect(ConversationReplyMailer).to receive(:reply).and_return(mailer)
        expect(mailer).to receive(:deliver_now).and_raise(StandardError.new("SMTP Error"))

        expect(Rails.logger).to receive(:error).with(/ServicePicker Email Delivery Error/)
        expect(message).to receive(:update_column).with(:status, :failed)

        expect { service.call }.to raise_error(StandardError, "SMTP Error")
      end
    end

    context 'with WebWidget channel' do
      let(:default_channel) { double('Channel::WebWidget', class: double(name: 'Channel::WebWidget')) }
      let(:service) { described_class.new(conversation: conversation, message: message) }

      before do
        stub_const('Messages::OfflineReplyWorker', double('Worker'))
      end

      it 'enqueues offline reply worker' do
        expect(Messages::OfflineReplyWorker).to receive(:perform_in).with(5.minutes, 2, 10)
        service.call
      end
    end

    context 'with Whatsapp channel' do
      let(:default_channel) { double('Channel::Whatsapp', class: double(name: 'Channel::Whatsapp')) }
      let(:service) { described_class.new(conversation: conversation, message: message) }

      before do
        stub_const('Channels::Whatsapp::CloudApi::MessageSender', double('Sender'))
      end

      it 'calls whatsapp message sender' do
        expect(Channels::Whatsapp::CloudApi::MessageSender).to receive(:call).with(
          whatsapp_channel: default_channel,
          customer_inbox: customer_inbox,
          message: message
        )
        service.call
      end
    end

    context 'with API / Custom channel' do
      let(:default_channel) { double('Channel::Custom', class: double(name: 'Channel::Custom'), webhook_url: 'http://hook.com') }
      let(:service) { described_class.new(conversation: conversation, message: message) }

      before do
        stub_const('Webhook::Delivery', double('WebhookDeliveryClass'))
        stub_const('Integrations::Webhooks::BroadcasterWorker', double('Worker'))
      end

      it 'creates delivery and enqueues broadcaster' do
        allow(message).to receive(:as_json).and_return({ "msg" => 1 })
        allow(conversation).to receive(:as_json).and_return({ "conv" => 2 })
        
        delivery = double('Delivery', id: 55)
        expect(Webhook::Delivery).to receive(:create!).with(
          hash_including(
            resource: default_channel,
            endpoint_url: 'http://hook.com',
            event_name: 'message.created'
          )
        ).and_return(delivery)

        expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(55, 1)
        
        service.call
      end
    end

    context 'with unimplemented channel' do
      let(:default_channel) { double('Channel::Unknown', class: double(name: 'Channel::Unknown')) }
      let(:service) { described_class.new(conversation: conversation, message: message) }

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/No delivery service implemented for Channel::Unknown/)
        service.call
      end
    end
  end
end

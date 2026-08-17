# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationDeliveryWorker, type: :worker do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }
  let(:notification) { create(:notification, account: account, user: user, resource: conversation, event: :conversation_created) }
  let!(:setting) { create(:notification_setting, account: account, user: user) }
  let(:mailer_class) do
    Class.new do
      def self.notify(*); end
    end
  end

  before do
    stub_const('AgentNotificationMailer', mailer_class)
  end

  describe '#perform' do
    it 'delivers notification via ActionCable, email, and push' do
      expect(ActionCable.server).to receive(:broadcast).with(
        user.connection_token,
        { event: 'notification.created', object: notification.event_payload }
      )

      mail_double = double('mail', deliver_later: true)
      expect(AgentNotificationMailer).to receive(:notify).with(notification).and_return(mail_double)

      described_class.new.perform(notification.id, account.id)
    end

    it 'returns early if notification is not found' do
      expect(ActionCable.server).not_to receive(:broadcast)
      expect(AgentNotificationMailer).not_to receive(:notify)

      described_class.new.perform(SecureRandom.uuid, account.id)
    end

    it 'does not send email if email notifications for event are disabled' do
      setting.update!(email_flags: 0)
      allow(ActionCable.server).to receive(:broadcast)
      expect(AgentNotificationMailer).not_to receive(:notify)

      described_class.new.perform(notification.id, account.id)
    end

    context 'when event is message_created' do
      let(:message) { create(:message, account: account, conversation: conversation) }
      let(:msg_notification) { create(:notification, account: account, user: user, resource: message, event: :message_created) }

      it 'skips email if unread count is zero' do
        allow(ActionCable.server).to receive(:broadcast)
        allow(::RedisUtilities::Helpers).to receive(:hash_get).and_return('0')
        expect(AgentNotificationMailer).not_to receive(:notify)

        described_class.new.perform(msg_notification.id, account.id)
      end

      it 'sends email if unread count is greater than zero' do
        allow(ActionCable.server).to receive(:broadcast)
        allow(::RedisUtilities::Helpers).to receive(:hash_get).and_return('2')
        mail_double = double('mail', deliver_later: true)
        expect(AgentNotificationMailer).to receive(:notify).with(msg_notification).and_return(mail_double)

        described_class.new.perform(msg_notification.id, account.id)
      end
    end
  end
end

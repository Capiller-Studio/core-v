# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSubscription, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  describe 'Associations and Enums' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to define_enum_for(:subscription_type).with_values(push: 0, fcm: 1) }
  end

  describe 'web push delivery and tokens' do
    let(:sub) do
      account.with_shard do
        described_class.create!(
          user: user,
          subscription_type: :push,
          data: {
            'endpoint' => 'https://fcm.googleapis.com/fcm/send/xyz',
            'p256dh' => 'BDm123...',
            'auth' => 'auth456...'
          }
        )
      end
    end

    it 'extracts push token and web push keys' do
      expect(sub.push_token).to eq('https://fcm.googleapis.com/fcm/send/xyz')
      expect(sub.web_push_keys).to eq({ p256dh: 'BDm123...', auth: 'auth456...' })
    end

    it 'delivers web push via DeskbolicWebPush' do
      notification = create(:notification, account: account, user: user, event: :conversation_created)
      expect(DeskbolicWebPush).to receive(:payload_send)

      sub.deliver_push!(notification)
    end
  end
end

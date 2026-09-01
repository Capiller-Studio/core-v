# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trackable, type: :model do
  let(:account) { create(:account) }

  describe 'State snapshots and diffs for undo/rollback' do
    let(:channel) do
      account.with_shard do
        Channel::Whatsapp.create!(
          account: account,
          phone_number_id: "phone_#{SecureRandom.hex(6)}",
          business_account_id: "biz_#{SecureRandom.hex(6)}",
          full_phone_number: "+1555#{rand(1000000..9999999)}",
          api_key: 'EAABwz12345secretkey'
        )
      end
    end

    it 'captures full attributes in snapshot_payload for historical recovery' do
      snapshot = channel.snapshot_payload
      expect(snapshot['api_key']).to eq('EAABwz12345secretkey')
      expect(snapshot['phone_number_id']).to eq(channel.phone_number_id)
    end

    it 'captures full attribute diffs in changes_payload' do
      account.with_shard do
        channel.update!(api_key: 'new_super_secret_key_999')
      end

      changes = channel.changes_payload
      expect(changes['api_key']).to eq(['EAABwz12345secretkey', 'new_super_secret_key_999'])
    end

    it 'captures nested attributes in email smtp configurations' do
      email_channel = account.with_shard do
        Channel::Email.create!(
          account: account,
          email: "support_#{SecureRandom.hex(4)}@example.com",
          smtp_configurations: {
            'address' => 'smtp.example.com',
            'port' => 587,
            'username' => 'support',
            'password' => 'secret_password_123'
          },
          imap_configurations: {
            'address' => 'imap.example.com',
            'port' => 993,
            'username' => 'support',
            'password' => 'secret_imap_password_123'
          }
        )
      end

      snapshot = email_channel.snapshot_payload
      expect(snapshot['smtp_configurations']['password']).to eq('secret_password_123')
      expect(snapshot['smtp_configurations']['address']).to eq('smtp.example.com')
      expect(snapshot['imap_configurations']['password']).to eq('secret_imap_password_123')
    end

    it 'captures standard attribute changes' do
      label = account.with_shard do
        Label.create!(account: account, title: 'VIP Support', color: '#ff0000')
      end

      account.with_shard do
        label.update!(title: 'High Priority')
      end

      changes = label.changes_payload
      expect(changes['title']).to eq(['VIP Support', 'High Priority'])
    end
  end

  describe 'Lifecycle callbacks' do
    it 'calls Activities::Recorder on update' do
      label = account.with_shard do
        Label.create!(account: account, title: 'Bug', color: '#00ff00')
      end

      expect(Activities::Recorder).to receive(:call).with(
        hash_including(
          trackable: label,
          event_type: :update
        )
      )

      account.with_shard do
        label.update!(title: 'Critical Bug')
      end
    end

    it 'calls Activities::Recorder on destroy' do
      label = account.with_shard do
        Label.create!(account: account, title: 'To Delete', color: '#000000')
      end

      expect(Activities::Recorder).to receive(:call).with(
        hash_including(
          trackable: label,
          event_type: :destroy
        )
      )

      account.with_shard do
        label.destroy!
      end
    end
  end
end

# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    class SyncTemplatesWorker
      include Sidekiq::Worker

      sidekiq_options queue: :default, retry: 3

      def perform(account_id = nil, channel_id = nil)
        if account_id.present? && channel_id.present?
          sync_single_channel(account_id, channel_id)
        else
          sync_all_active_channels
        end
      end

      private

      def sync_single_channel(account_id, channel_id)
        account = Account.find_by(id: account_id)
        return unless account

        account.with_shard do
          channel = Channel::Whatsapp.find_by(id: channel_id)
          return unless channel

          channel.sync_templates
        end
      rescue StandardError => e
        Rails.logger.error("SyncTemplatesWorker failed for account #{account_id}, channel #{channel_id}: #{e.message}")
      end

      def sync_all_active_channels
        Account.find_each do |account|
          account.with_shard do
            Channel::Whatsapp.where(status: :active).find_each do |channel|
              self.class.perform_async(account.id, channel.id)
            end
          end
        end
      end
    end
  end
end

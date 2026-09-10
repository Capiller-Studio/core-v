# frozen_string_literal: true

namespace :messages do
  desc "Fix echo messages across channels that were incorrectly created with sender as Customer instead of Account"
  task fix_echo_senders: :environment do
    puts "==================================================================="
    puts " Starting Backfill: Fix Echo Message Senders to Account"
    puts "==================================================================="

    echo_external_ids = Set.new

    # Step 1: Scan Webhook::Incoming for historical echo events
    if ActiveRecord::Base.connection.table_exists?("webhook_incomings")
      puts "1. Scanning Webhook::Incoming logs for echo payloads..."
      Webhook::Incoming.find_each do |webhook|
        payload = webhook.payload || {}

        # Check Instagram
        if webhook.source == "instagram" || payload["object"] == "instagram"
          Array(payload["entry"]).each do |entry|
            messages = Array(entry["messaging"]).presence || Array(entry["standby"]) || []
            messages.each do |msg|
              if msg.dig("message", "is_echo") == true
                mid = msg.dig("message", "mid")
                echo_external_ids.add(mid) if mid.present?
              end
            end
          end
        # Check Facebook
        elsif webhook.source == "facebook" || payload["object"] == "page" || webhook.event_type.to_s == "message_echo"
          Array(payload["entry"]).each do |entry|
            messages = Array(entry["messaging"]).presence || Array(entry["standby"]) || []
            messages.each do |msg|
              if msg.dig("message", "is_echo") == true || webhook.event_type.to_s == "message_echo"
                mid = msg.dig("message", "mid")
                echo_external_ids.add(mid) if mid.present?
              end
            end
          end
        # Check WhatsApp
        elsif webhook.source == "whatsapp" || payload["object"] == "whatsapp_business_account"
          Array(payload["entry"]).each do |entry|
            Array(entry["changes"]).each do |change|
              val = change["value"] || {}
              Array(val["message_echoes"]).each do |echo_msg|
                id = echo_msg["id"]
                echo_external_ids.add(id) if id.present?
              end
            end
          end
        end
      end
      puts "Found #{echo_external_ids.size} echo message IDs from webhook logs."
    end

    # Step 2: Iterate across all accounts and shards to update messages
    total_updated = 0
    Account.find_each do |account|
      account.with_shard do
        if echo_external_ids.any?
          messages_to_fix = account.messages.where(external_id: echo_external_ids.to_a, sender_type: "Customer")
          count = messages_to_fix.count
          if count > 0
            messages_to_fix.update_all(sender_type: "Account", sender_id: account.id)
            total_updated += count
            puts "Account #{account.name} (#{account.id}): Updated #{count} messages from webhook echo logs."
          end
        end
      end
    end

    puts "==================================================================="
    puts " Backfill Complete: Fixed #{total_updated} messages to sender_type: 'Account'"
    puts "==================================================================="
  end
end

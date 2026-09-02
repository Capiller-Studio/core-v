# frozen_string_literal: true

namespace :webhooks do
  desc "Unsubscribe all external channel webhooks (from Meta App discovery, historical logs, and DB) before DB wipe"
  task unsubscribe_all: :environment do
    puts "==================================================================="
    puts " Starting Comprehensive Webhook Unsubscription from External APIs"
    puts "==================================================================="

    whatsapp_app_id = (Rails.application.credentials.dig(:channels, :whatsapp, :app_id).presence ||
                       Rails.application.credentials.dig(:channels, :facebook, :app_id))&.to_s&.strip
    whatsapp_app_secret = (Rails.application.credentials.dig(:channels, :whatsapp, :app_secret).presence ||
                           Rails.application.credentials.dig(:channels, :facebook, :app_secret))&.to_s&.strip

    app_token = "#{whatsapp_app_id}|#{whatsapp_app_secret}" if whatsapp_app_id.present? && whatsapp_app_secret.present?

    waba_ids = Set.new
    page_ids = Set.new
    ig_ids   = Set.new

    # A. Discover from Webhook::Incoming history if table exists
    if ActiveRecord::Base.connection.table_exists?("webhook_incomings")
      puts "\n1. Scanning historical Webhook::Incoming logs for orphaned IDs..."
      Webhook::Incoming.find_each do |w|
        payload = w.payload || {}
        # WABA discovery from payload
        if payload["object"] == "whatsapp_business_account" || w.source == "whatsapp"
          entry_id = payload.dig("entry", 0, "id")
          waba_info_id = payload.dig("entry", 0, "changes", 0, "value", "waba_info", "waba_id")
          waba_ids.add(entry_id.to_s) if entry_id.present?
          waba_ids.add(waba_info_id.to_s) if waba_info_id.present?
        elsif payload["object"] == "instagram" || w.source == "instagram"
          ig_id = payload.dig("entry", 0, "id")
          ig_ids.add(ig_id.to_s) if ig_id.present?
        elsif payload["object"] == "page" || w.source == "facebook"
          p_id = payload.dig("entry", 0, "id")
          page_ids.add(p_id.to_s) if p_id.present?
        end
      end
      puts "Found #{waba_ids.size} WhatsApp WABAs, #{ig_ids.size} Instagram IDs, #{page_ids.size} Facebook Page IDs from logs."
    end

    # B. Discover from Meta Graph API directly via Tech Provider App Access Token
    if app_token.present?
      puts "\n2. Querying Meta Graph API directly via Tech Provider App (#{whatsapp_app_id})..."
      
      # Try fetching client WABAs linked to app
      begin
        resp = HTTParty.get(
          "https://graph.facebook.com/v26.0/#{whatsapp_app_id}/whatsapp_business_accounts",
          query: { access_token: app_token }
        )
        if resp.success? && resp["data"].is_a?(Array)
          resp["data"].each { |item| waba_ids.add(item["id"].to_s) if item["id"].present? }
        end
      rescue StandardError => e
        puts "Meta App WABA query notice: #{e.message}"
      end

      # Try fetching App Webhook Subscriptions
      begin
        sub_resp = HTTParty.get(
          "https://graph.facebook.com/v26.0/#{whatsapp_app_id}/subscriptions",
          query: { access_token: app_token }
        )
        puts "Current Meta App Subscribed Webhook Objects: #{sub_resp['data']&.map { |d| d['object'] }&.join(', ')}" if sub_resp.success?
      rescue StandardError => e
        puts "Meta App Subscriptions query notice: #{e.message}"
      end
    end

    # C. Discover from existing database records if any exist
    if ActiveRecord::Base.connection.table_exists?("accounts")
      puts "\n3. Scanning active database records..."
      Account.find_each do |account|
        account.with_shard do
          if ActiveRecord::Base.connection.table_exists?("channel_whatsapps")
            Channel::Whatsapp.find_each { |c| waba_ids.add(c.business_account_id.to_s) if c.business_account_id.present? }
          end
          if ActiveRecord::Base.connection.table_exists?("channel_facebook_pages")
            Channel::FacebookPage.find_each { |c| page_ids.add(c.page_identifier.to_s) if c.page_identifier.present? }
          end
          if ActiveRecord::Base.connection.table_exists?("channel_instagram")
            Channel::Instagram.find_each { |c| ig_ids.add(c.instagram_id.to_s) if c.instagram_id.present? }
          end
        end
      end
    end

    # D. Execute Unsubscriptions on Meta Graph API
    puts "\n========================================================"
    puts " Executing Webhook Deletions on Meta"
    puts "========================================================"

    # 1. WhatsApp WABAs
    puts "\n--- Unsubscribing WhatsApp WABAs (#{waba_ids.size} total) ---"
    waba_ids.each do |waba_id|
      print "Unsubscribing WABA #{waba_id}... "
      resp = HTTParty.delete(
        "https://graph.facebook.com/v26.0/#{waba_id}/subscribed_apps",
        headers: {
          "Authorization" => "Bearer #{app_token}",
          "Content-Type" => "application/json"
        }
      ) rescue nil

      if resp&.success?
        puts "✓ SUCCESS (#{resp.code})"
      else
        puts "STATUS: #{resp&.code || 'ERR'} - #{resp&.body&.truncate(100)}"
      end
    end

    # 2. Instagram IDs
    puts "\n--- Unsubscribing Instagram Objects (#{ig_ids.size} total) ---"
    ig_ids.each do |ig_id|
      print "Unsubscribing Instagram #{ig_id}... "
      resp = HTTParty.delete(
        "https://graph.facebook.com/v26.0/#{ig_id}/subscribed_apps",
        query: { access_token: app_token }
      ) rescue nil

      if resp&.success?
        puts "✓ SUCCESS (#{resp.code})"
      else
        puts "STATUS: #{resp&.code || 'ERR'} - #{resp&.body&.truncate(100)}"
      end
    end

    # 3. Facebook Pages
    puts "\n--- Unsubscribing Facebook Pages (#{page_ids.size} total) ---"
    page_ids.each do |p_id|
      print "Unsubscribing Facebook Page #{p_id}... "
      resp = HTTParty.delete(
        "https://graph.facebook.com/v26.0/#{p_id}/subscribed_apps",
        query: { access_token: app_token }
      ) rescue nil

      if resp&.success?
        puts "✓ SUCCESS (#{resp.code})"
      else
        puts "STATUS: #{resp&.code || 'ERR'} - #{resp&.body&.truncate(100)}"
      end
    end

    puts "\n==================================================================="
    puts " All Webhook Unsubscriptions Completed!"
    puts "==================================================================="
  end
end

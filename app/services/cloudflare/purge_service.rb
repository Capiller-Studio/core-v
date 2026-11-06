# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Cloudflare
  class PurgeService
    PURGE_ENDPOINT = "https://api.cloudflare.com/client/v4/zones/%{zone_id}/purge_cache"

    def self.purge_channel(channel)
      case channel
      when Channel::ContactForm
        purge_contact_form(channel)
      when Channel::WebWidget
        purge_web_widget(channel)
      else
        { success: false, reason: :unsupported_channel_type }
      end
    end

    def self.purge_contact_form(channel)
      base = widget_base_url
      urls = [
        "#{base}/f/#{channel.account_id}/#{channel.id}/embed.js",
        "#{base}/f/#{channel.account_id}/#{channel.id}"
      ]

      Core::SUPPORTED_LOCALES.each do |locale|
        urls << "#{base}/#{locale}/f/#{channel.account_id}/#{channel.id}"
      end

      purge_urls(urls)
    end

    def self.purge_web_widget(channel)
      base = widget_base_url
      urls = [
        "#{base}/w/#{channel.account_id}/#{channel.id}/embed.js",
        "#{base}/w/#{channel.account_id}/#{channel.id}"
      ]

      Core::SUPPORTED_LOCALES.each do |locale|
        urls << "#{base}/#{locale}/w/#{channel.account_id}/#{channel.id}"
      end

      purge_urls(urls)
    end

    def self.purge_urls(urls)
      zone_id = ENV["CLOUDFLARE_ZONE_ID"]
      token   = ENV["CLOUDFLARE_API_TOKEN"]

      files = urls.flatten.compact.map(&:to_s).uniq
      return { success: false, reason: :empty_urls } if files.empty?

      unless zone_id.present? && token.present?
        Rails.logger.info("[Cloudflare::PurgeService] Cloudflare credentials missing, skipping edge cache purge for #{files.size} URLs.")
        return { success: true, purged: 0, skipped: true, reason: :missing_credentials }
      end

      uri = URI(format(PURGE_ENDPOINT, zone_id: zone_id))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request.body = { files: files }.to_json

      response = http.request(request)
      body = JSON.parse(response.body) rescue {}

      if response.is_a?(Net::HTTPSuccess) && body["success"]
        Rails.logger.info("[Cloudflare::PurgeService] Successfully purged #{files.size} URLs from Cloudflare cache.")
        { success: true, purged: files.size, response: body }
      else
        Rails.logger.warn("[Cloudflare::PurgeService] Cloudflare purge failed: #{body['errors']}")
        { success: false, errors: body["errors"], status: response.code }
      end
    rescue StandardError => e
      Rails.logger.error("[Cloudflare::PurgeService] Exception during Cloudflare cache purge: #{e.message}")
      { success: false, error: e.message }
    end

    def self.widget_base_url
      (ENV["WIDGET_APP_URL"].presence || "https://widget-rely.capiller.com").delete_suffix("/")
    end
  end
end

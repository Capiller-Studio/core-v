# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  class ChannelCreator < ApplicationService
    attr_accessor :channel_type, :channel_params, :current_account
    attr_reader :channel

    def initialize(channel_type:, channel_params:, current_account:)
      self.channel_type      = channel_type
      self.channel_params    = channel_params
      self.current_account   = current_account
    end

    def call
      current_account.with_shard do
        ShardRecord.transaction do
          create_channel if channel_type.present?
          true
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("ChannelCreator Validation Failed: #{e.message}")
      false
    rescue StandardError => e
      Rails.logger.error("ChannelCreator Failed: #{e.message}")
      channel.errors.add(:base, e.message) if channel
      false
    end

    private

    def create_channel
      send("#{channel_type.underscore.parameterize(separator: '_')}_channel")
    end

    def web_widget_channel
      @channel = Channel::WebWidget.new(
        name: channel_params[:name],
        website_url: channel_params[:website_url],
        ui_configurations: channel_params[:ui_configurations] || {},
        configurations: channel_params[:configurations] || {},
        account: current_account
      )
      @channel.save!

      inbox_attrs = { name: channel_params[:name], account: current_account, primary_inbox: true }
      inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h) if channel_params[:primary_inbox_attributes].present?
      @channel.inboxes.create!(inbox_attrs)
    end

    def email_channel
      @channel = Channel::Email.new(channel_params.except(:primary_inbox_attributes))
      @channel.account = current_account
      
      # We throw an error here if validation fails so that the transaction rolls back
      @channel.save!

      inbox_attrs = {
        name: channel_params[:name],
        account: current_account,
        primary_inbox: true
      }
      
      if channel_params[:primary_inbox_attributes].present?
        inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h)
      end

      @channel.inboxes.create!(inbox_attrs)
    end

    def contact_form_channel
      @channel = Channel::ContactForm.new(
        name: channel_params[:name],
        account: current_account,
        configurations: {
          submit_redirect_url: channel_params[:submit_redirect_url],
          notification_emails: channel_params[:notification_emails]&.split(",")&.map(&:strip),
          success_message_i18n_key: channel_params[:success_message_i18n_key] || "contact_form.success"
        }
      )

      @channel.require_login = channel_params[:require_login] == "true"
      @channel.allow_attachments = channel_params[:allow_attachments] == "true"
      @channel.send_confirmation_email = channel_params[:send_confirmation_email] == "true"
      @channel.save!

      inbox_attrs = { name: channel_params[:name], account: current_account, primary_inbox: true }
      inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h) if channel_params[:primary_inbox_attributes].present?
      @channel.inboxes.create!(inbox_attrs)
    end

    def facebook_page_channel
      @channel = Channel::FacebookPage.new(
        name: channel_params[:name],
        access_token: JSON.parse(channel_params[:page_data])["access_token"],
        page_identifier: JSON.parse(channel_params[:page_data])["id"],
        account: current_account
      )
      @channel.save!

      inbox_attrs = { name: JSON.parse(channel_params[:page_data])["name"], account: current_account, primary_inbox: true }
      inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h) if channel_params[:primary_inbox_attributes].present?
      @channel.inboxes.create!(inbox_attrs)
    end

    def whatsapp_channel
      @channel = Channel::Whatsapp.new(
        name: channel_params[:name],
        api_key: channel_params[:api_key],
        full_phone_number: channel_params[:full_phone_number],
        phone_number_id: channel_params[:phone_number_id],
        business_account_id: channel_params[:business_account_id],
        account: current_account,
        service: :cloud_api
      )
      @channel.save!

      inbox_attrs = { name: channel_params[:name], account: current_account, primary_inbox: true }
      inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h) if channel_params[:primary_inbox_attributes].present?
      @channel.inboxes.create!(inbox_attrs)
    end
  end
end

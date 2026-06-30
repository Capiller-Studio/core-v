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
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
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
        channel_params.except(:primary_inbox_attributes, :anonymous_allowed, :help_center_enabled, :pre_chat_form_enabled, :secure_identity_enforced, :custom_branding)
      )
      @channel.account = current_account
      
      @channel.anonymous_allowed = channel_params[:anonymous_allowed] == "true" || channel_params[:anonymous_allowed] == "1" || channel_params[:anonymous_allowed] == true
      @channel.help_center_enabled = channel_params[:help_center_enabled] == "true" || channel_params[:help_center_enabled] == "1" || channel_params[:help_center_enabled] == true
      @channel.pre_chat_form_enabled = channel_params[:pre_chat_form_enabled] == "true" || channel_params[:pre_chat_form_enabled] == "1" || channel_params[:pre_chat_form_enabled] == true
      @channel.secure_identity_enforced = channel_params[:secure_identity_enforced] == "true" || channel_params[:secure_identity_enforced] == "1" || channel_params[:secure_identity_enforced] == true
      @channel.custom_branding = channel_params[:custom_branding] == "true" || channel_params[:custom_branding] == "1" || channel_params[:custom_branding] == true

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
        submit_redirect_url: channel_params[:submit_redirect_url],
        outbound_channel_id: channel_params[:outbound_channel_id],
        outbound_channel_type: channel_params[:outbound_channel_type]
      )

      @channel.require_login = channel_params[:require_login] == "true" || channel_params[:require_login] == "1" || channel_params[:require_login] == true
      @channel.allow_attachments = channel_params[:allow_attachments] == "true" || channel_params[:allow_attachments] == "1" || channel_params[:allow_attachments] == true
      @channel.send_confirmation_email = channel_params[:send_confirmation_email] == "true" || channel_params[:send_confirmation_email] == "1" || channel_params[:send_confirmation_email] == true
      @channel.spam_protection_enabled = channel_params[:spam_protection_enabled] == "true" || channel_params[:spam_protection_enabled] == "1" || channel_params[:spam_protection_enabled] == true

      if channel_params[:translations_attributes].present?
        @channel.translations_attributes = channel_params[:translations_attributes]
      end

      if channel_params[:ui_configurations].present?
        @channel.ui_configurations = channel_params[:ui_configurations]
      end

      @channel.save!

      inbox_attrs = { name: channel_params[:name], account: current_account, primary_inbox: true }
      inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h) if channel_params[:primary_inbox_attributes].present?
      @channel.inboxes.create!(inbox_attrs)
    end

    def facebook_page_channel
      @channel = Channel::FacebookPage.new(
        name: channel_params[:name],
        access_token: channel_params[:access_token],
        user_access_token: channel_params[:user_access_token],
        page_identifier: channel_params[:page_identifier],
        avatar_url: channel_params[:avatar_url],
        account: current_account
      )
      @channel.save!

      inbox_attrs = { name: channel_params[:name], account: current_account, primary_inbox: true }
      inbox_attrs.merge!(channel_params[:primary_inbox_attributes].to_h) if channel_params[:primary_inbox_attributes].present?
      @channel.inboxes.create!(inbox_attrs)
    end

    def instagram_channel
      @channel = Channel::Instagram.new(
        instagram_id: channel_params[:instagram_id],
        username: channel_params[:username],
        name: channel_params[:name],
        avatar_url: channel_params[:avatar_url],
        access_token: channel_params[:access_token],
        expires_at: channel_params[:expires_at],
        account: current_account
      )
      @channel.save!

      inbox_attrs = { name: channel_params[:name] || channel_params[:username], account: current_account, primary_inbox: true }
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

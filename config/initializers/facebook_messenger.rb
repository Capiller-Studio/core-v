# frozen_string_literal: true

class DeskbolicFacebookProvider < Facebook::Messenger::Configuration::Providers::Base
  # Verify that the given verify token is valid.
  #
  # verify_token - A String sent by Facebook to verify the webhook endpoint.
  #
  # Returns a Boolean representing whether the verify token is valid.
  def valid_verify_token?(verify_token)
    verify_token == facebook_credentials(:verify_token)
  end

  # Find the right application secret.
  #
  # page_id - An Integer describing a Facebook Page ID.
  #
  # Returns a String describing the application secret.
  def app_secret_for(_page_id)
    facebook_credentials(:app_secret)
  end

  # Find the right access token.
  #
  # recipient - A Hash describing the `recipient` attribute of the message coming
  #             from Facebook.
  #
  # Note: The naming of "recipient" can throw you off, but think of it from the
  # perspective of the message: The "recipient" is the page that receives the
  # message.
  #
  # Returns a String describing an access token.
  def access_token_for(recipient)
    page_id = recipient.is_a?(String) ? recipient : recipient["id"]

    # Use GlobalRouting to look up which account/shard owns this page
    routing = GlobalRouting.find_by(route_type: "facebook_page", route_value: page_id)
    return nil unless routing

    routing.account.with_shard do
      Channel::FacebookPage.find_by(
        page_identifier: page_id,
        account_id: routing.account_id
      )&.access_token
    end
  end

  private

  def facebook_credentials(key)
    Rails.application.credentials.dig(:channels, :facebook, key)
  end
end

Rails.application.reloader.to_prepare do
  Facebook::Messenger.configure do |config|
    config.provider = DeskbolicFacebookProvider.new
  end

  Facebook::Messenger::Bot.on :message do |message|
    Webhooks::FacebookEventListenWorker.perform_async("message", message.to_json)
  end

  Facebook::Messenger::Bot.on :message_echo do |message|
    Webhooks::FacebookEventListenWorker.perform_async("message_echo", message.to_json)
  end

  Facebook::Messenger::Bot.on :delivery do |delivery|
    Webhooks::FacebookEventListenWorker.perform_async("delivery", delivery.to_json)
  end

  Facebook::Messenger::Bot.on :read do |read|
    Webhooks::FacebookEventListenWorker.perform_async("read", read.to_json)
  end
end

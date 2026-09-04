# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_facebook_pages
#
#  id                :uuid             not null, primary key
#  access_token      :string           not null
#  avatar_url        :string
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  name              :string
#  page_identifier   :string           not null
#  status            :integer          default("active"), not null
#  user_access_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#
# Indexes
#
#  index_channel_facebook_pages_on_account_id                      (account_id)
#  index_channel_facebook_pages_on_account_id_and_created_at       (account_id,created_at)
#  index_channel_facebook_pages_on_account_id_and_name             (account_id,name)
#  index_channel_facebook_pages_on_account_id_and_page_identifier  (account_id,page_identifier) UNIQUE
#  index_channel_facebook_pages_on_page_identifier                 (page_identifier)
#  index_channel_facebook_pages_on_status                          (status)
#
module Channel
  class FacebookPage < ShardRecord
    include Channelable
    include Routable
    include Reauthorizable
    include Trackable

    SUBSCRIBE_FIELDS = %w[
      messages
      message_echoes
      message_deliveries
      message_reads
      messaging_postbacks
    ].freeze

    belongs_to :account

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    accepts_nested_attributes_for :primary_inbox, update_only: true

    encrypts :access_token
    encrypts :user_access_token

    enum :status, { active: 0, disconnected: 1 }

    validates :page_identifier, presence: true, uniqueness: { scope: :account_id, message: "is already connected to this account" }
    validates :access_token, presence: true

    after_create :subscribe_to_webhooks
    before_destroy :unsubscribe_from_webhooks

    # Attempt to refresh the page access token using the stored long-lived user token.
    # The user token has a 60-day lifetime, and page tokens derived from it are permanent.
    def refresh_page_token!
      return unless user_access_token.present?

      client = Koala::Facebook::API.new(user_access_token)
      pages = client.get_connections("me", "accounts")
      page = pages.find { |p| p["id"] == page_identifier }

      if page
        update!(access_token: page["access_token"])
        reauthorized!
      else
        authorization_error!
      end
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.error("Facebook token refresh auth error for page #{page_identifier}: #{e.message}")
      authorization_error!
    rescue StandardError => e
      Rails.logger.error("Facebook token refresh error for page #{page_identifier}: #{e.message}")
    end

    private

    def subscribe_to_webhooks
      Facebook::Messenger::Subscriptions.subscribe(
        access_token:,
        subscribed_fields: SUBSCRIBE_FIELDS
      )
    rescue StandardError => e
      Rails.logger.error("Facebook webhook subscription failed for page #{page_identifier}: #{e.message}")
      errors.add(:base, "Webhook subscription failed: #{e.message}")
      throw(:abort)
    end

    def unsubscribe_from_webhooks
      Facebook::Messenger::Subscriptions.unsubscribe(access_token:)
    rescue StandardError => e
      Rails.logger.error("Facebook webhook unsubscribe failed for page #{page_identifier}: #{e.message}")
    end
  end
end

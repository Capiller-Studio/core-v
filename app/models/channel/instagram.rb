# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_instagram
#
#  id             :uuid             not null, primary key
#  access_token   :string           not null
#  avatar_url     :string
#  configurations :jsonb            not null
#  data           :jsonb            not null
#  expires_at     :datetime         not null
#  instagram_id   :string           not null
#  name           :string
#  status         :integer          default("active"), not null
#  username       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_channel_instagram_on_account_id                    (account_id)
#  index_channel_instagram_on_account_id_and_created_at     (account_id,created_at)
#  index_channel_instagram_on_account_id_and_instagram_id   (account_id,instagram_id) UNIQUE
#  index_channel_instagram_on_instagram_id                  (instagram_id) UNIQUE
#  index_channel_instagram_on_status                        (status)
#
module Channel
  class Instagram < ShardRecord
    include Channelable
    include Routable
    include Reauthorizable

    self.table_name = "channel_instagram"

    # Instagram tokens are more fragile (60-day lifetime, refreshable).
    # A single auth error is enough to flag the channel for re-authorization.
    AUTHORIZATION_ERROR_THRESHOLD = 1

    belongs_to :account

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"

    accepts_nested_attributes_for :primary_inbox, update_only: true

    encrypts :access_token

    enum :status, { active: 0, disconnected: 1 }

    validates :instagram_id, presence: true, uniqueness: true
    validates :access_token, presence: true
    validates :expires_at, presence: true

    # --- Routable overrides ---

    def routing_identifier
      instagram_id
    end

    def routing_type
      "instagram"
    end

    # --- Token lifecycle ---

    def token_expired?
      expires_at.present? && expires_at < Time.current
    end

    def token_expiring_soon?
      expires_at.present? && expires_at < 7.days.from_now
    end

    # Refresh the long-lived Instagram token using the ig_refresh_token grant type.
    # Instagram long-lived tokens can be refreshed as long as they are at least 24 hours
    # old and have not expired. A refreshed token is valid for 60 days from the time
    # of the refresh.
    def refresh_token!
      response = HTTParty.get(
        "https://graph.instagram.com/refresh_access_token",
        query: {
          grant_type: "ig_refresh_token",
          access_token: access_token
        }
      )

      result = JSON.parse(response.body)

      if response.success? && result["access_token"].present?
        update!(
          access_token: result["access_token"],
          expires_at: Time.current + result["expires_in"].to_i.seconds
        )
        reauthorized!
      else
        Rails.logger.error("Instagram token refresh failed for #{instagram_id}: #{result['error']}")
        authorization_error!
      end
    end
  end
end

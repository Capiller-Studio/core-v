# frozen_string_literal: true

module RedisUtilities
  module Keys
    INBOX_AGENTS = "INBOX:%{account_id}:%{inbox_id}:AGENTS"
    PENDING_EMAIL = "PENDING_EMAIL:%{account_id}:%{id}"
    ONLINE_STATUS = "ONLINE_STATUS:%{account_id}"
    CUSTOMERS_ACTIVITY = "CUSTOMERS:%{account_id}:ACTIVITY"
    USERS_ACTIVITY = "USERS:%{account_id}:ACTIVITY"
    EMAIL_LOCK = "EMAIL_LOCK:%{account_id}:%{id}"

    AUTHORIZATION_ERROR_COUNT = "AUTHORIZATION_ERROR_COUNT:%{resource_name}:%{resource_id}"
    REAUTHORIZATION_REQUIRED =  "REAUTHORIZATION_REQUIRED:%{resource_name}:%{resource_id}"

    MESSAGE_CREATION_LOCK = "MESSAGE_CREATION_LOCK:%{account_id}:%{id}"
    INSTAGRAM_MESSAGE_CREATION_LOCK = "INSTAGRAM_MESSAGE_CREATION_LOCK:%{instagram_id}:%{sender_id}"
    FACEBOOK_MESSAGE_CREATION_LOCK = "FACEBOOK_MESSAGE_CREATION_LOCK:%{receiver_id}:%{sender_id}"
    INBOX_ROUND_ROBIN = "INBOX:%{account_id}:%{inbox_id}:ROUND_ROBIN"

    SUBSCRIPTION_LOCK = "SUBSCRIPTION_LOCK:%{account_id}"
    WALLET_LOCK = "WALLET_LOCK:%{account_id}"
    CHARGE_LOCK = "CHARGE_LOCK:%{account_id}"
    RENEWAL_LOCK = "RENEWAL_LOCK:%{account_id}"
  end
end

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
    CUSTOMER_CREATION_LOCK = "CUSTOMER_CREATION_LOCK:%{account_id}:%{identifier}"
    INSTAGRAM_MESSAGE_CREATION_LOCK = "INSTAGRAM_MESSAGE_CREATION_LOCK:%{instagram_id}:%{sender_id}"
    FACEBOOK_MESSAGE_CREATION_LOCK = "FACEBOOK_MESSAGE_CREATION_LOCK:%{receiver_id}:%{sender_id}"
    WHATSAPP_MESSAGE_CREATION_LOCK = "WHATSAPP_MESSAGE_CREATION_LOCK:%{receiver_id}:%{sender_id}"
    INBOX_ROUND_ROBIN = "INBOX:%{account_id}:%{inbox_id}:ROUND_ROBIN"
    TEAM_ROUND_ROBIN = "TEAM:%{account_id}:%{team_id}:ROUND_ROBIN"
    POLICY_ROUND_ROBIN = "POLICY:%{account_id}:%{policy_id}:ROUND_ROBIN"

    AI_CLASSIFIER_LOCK = "AI_CLASSIFIER_LOCK:%{account_id}:%{conversation_id}"
    LANGUAGE_DETECTION_LOCK = "LANGUAGE_DETECTION_LOCK:%{account_id}:%{conversation_id}"
    LIMIT_NOTIFICATION_LOCK = "LIMIT_NOTIFICATION:%{account_id}:%{resource}:%{threshold}:%{window}"

    SUBSCRIPTION_LOCK = "SUBSCRIPTION_LOCK:%{account_id}"
    WALLET_LOCK = "WALLET_LOCK:%{account_id}"
    CHARGE_LOCK = "CHARGE_LOCK:%{account_id}"
    RENEWAL_LOCK = "RENEWAL_LOCK:%{account_id}"
    COMMISSION_LOCK = "COMMISSION_LOCK:%{transaction_id}"
    PAYOUT_LOCK = "PAYOUT_LOCK:%{profile_id}"
    PAYOUT_BATCH_LOCK = "PAYOUT_BATCH_LOCK:%{batch_id}"
    PAYOUT_GENERATION_LOCK = "PAYOUT_GENERATION_LOCK"
    PAYMENT_METHOD_LOCK = "PAYMENT_METHOD_LOCK:%{account_id}"
    WEBHOOK_EVENT_LOCK = "WEBHOOK_EVENT_LOCK:%{provider}:%{event_id}"

    UNREAD_CONVERSATION_COUNT = "UNREAD:%{account_id}:%{member_id}:CONVERSATIONS"
    UNREAD_CONVERSATION_SET = "UNREAD:%{account_id}:%{member_id}:CONVERSATIONS_SET"
    UNREAD_MENTION_COUNT = "UNREAD:%{account_id}:%{member_id}:MENTIONS"
    UNREAD_INBOX_COUNT = "UNREAD:%{account_id}:%{member_id}:INBOXES"
  end
end

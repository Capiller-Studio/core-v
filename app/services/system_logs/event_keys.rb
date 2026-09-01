# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module SystemLogs
  module EventKeys
    # Webhooks and Channel Events
    WEBHOOK_FACEBOOK_AUTH_ERROR             = "webhook.facebook.auth_error"
    WEBHOOK_FACEBOOK_ERROR                  = "webhook.facebook.error"
    WEBHOOK_INSTAGRAM_AUTH_ERROR            = "webhook.instagram.auth_error"
    WEBHOOK_INSTAGRAM_ERROR                 = "webhook.instagram.error"
    WEBHOOK_WHATSAPP_AUTH_ERROR             = "webhook.whatsapp.auth_error"
    WEBHOOK_WHATSAPP_ERROR                  = "webhook.whatsapp.error"
    WEBHOOK_WHATSAPP_CONVERSATION_CREATED   = "webhook.whatsapp.conversation_created"
    WEBHOOK_CUSTOM_DELIVERY_FAILED          = "webhook.custom.delivery_failed"

    # Channel Lifecycle & Mutations
    CHANNEL_REAUTHORIZATION_REQUIRED        = "channel.reauthorization_required"
    CHANNEL_MUTATION_FAILED                 = "channel.mutation_failed"
    CHANNEL_REFRESH_TOKEN_FAILED            = "channel.refresh_token_failed"

    # Auth and Security
    AUTH_LOGIN_FAILED                       = "auth.login_failed"
    AUTH_ACCOUNT_LOCKED                     = "auth.account_locked"
    AUTH_STAFF_LOGIN_FAILED                 = "auth.staff_login_failed"

    # Billing and Subscriptions
    BILLING_SUBSCRIPTION_CREATED            = "billing.subscription_created"
    BILLING_PAYMENT_FAILED                  = "billing.payment_failed"
    BILLING_PAYMENT_SUCCEEDED               = "billing.payment_succeeded"
    BILLING_TRIAL_EXPIRED                   = "billing.trial_expired"

    # System & Maintenance
    SYSTEM_PRUNED_LOGS                      = "system.pruned_logs"
    SYSTEM_WORKER_FAILED                    = "system.worker_failed"

    ALL = constants.map { |c| const_get(c) }.freeze
  end
end

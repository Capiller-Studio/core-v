# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_stripe_signature

    def create
      event = construct_event
      return head(:bad_request) unless event

      ActiveRecord::Base.transaction do
        case event.type
        when "checkout.session.completed"
          handle_checkout_completed(event.data.object)
        when "invoice.paid"
          handle_invoice_paid(event.data.object)
        when "invoice.payment_failed"
          handle_payment_failed(event.data.object)
        when "customer.subscription.updated"
          handle_subscription_updated(event.data.object)
        when "customer.subscription.deleted"
          handle_subscription_deleted(event.data.object)
        when "payment_method.attached"
          handle_payment_method_attached(event.data.object)
        end
      end

      head(:ok)
    rescue StandardError => e
      Rails.logger.error("Stripe webhook error: #{e.message}")
      head(:bad_request)
    end

    private

    def verify_stripe_signature
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

      begin
        ::Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue ::Stripe::SignatureVerificationError
        head(:unauthorized)
      end
    end

    def construct_event
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

      ::Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError, ::Stripe::SignatureVerificationError
      nil
    end

    def handle_checkout_completed(session)
      account = Account.find(session.metadata.account_id)
      plan = Plan.find(session.metadata.plan_id)
      billing_cycle = session.metadata.billing_cycle

      Billing::SubscriptionCreator.call(
        account:,
        plan:,
        billing_cycle: billing_cycle.to_sym
      )
    end

    def handle_invoice_paid(invoice)
      subscription = Subscription.find_by(external_id: invoice.subscription)
      return unless subscription

      Transaction.create!(
        account: subscription.account,
        subscription:,
        transaction_type: :charge,
        status: :completed,
        amount: invoice.amount_paid / 100.0,
        currency: invoice.currency.upcase,
        provider: :stripe,
        external_id: invoice.id,
        description: "Stripe invoice payment"
      )
    end

    def handle_payment_failed(invoice)
      subscription = Subscription.find_by(external_id: invoice.subscription)
      return unless subscription

      subscription.update!(status: :past_due)

      owner = subscription.account.account_users.find_by(role: :owner)&.user
      return unless owner

      Notification.create!(
        account: subscription.account,
        user: owner,
        resource: subscription,
        event: :payment_failed
      )
    end

    def handle_subscription_updated(stripe_sub)
      subscription = Subscription.find_by(external_id: stripe_sub.id)
      return unless subscription

      subscription.update!(
        current_period_start: Time.zone.at(stripe_sub.current_period_start),
        current_period_end: Time.zone.at(stripe_sub.current_period_end)
      )
    end

    def handle_subscription_deleted(stripe_sub)
      subscription = Subscription.find_by(external_id: stripe_sub.id)
      return unless subscription

      Billing::SubscriptionCanceller.call(subscription:, immediate: true)
    end

    def handle_payment_method_attached(pm)
      account = Account.joins(:subscriptions)
                       .find_by(billing_data: { stripe_customer_id: pm.customer }.to_json)
      return unless account

      PaymentMethod.create!(
        account:,
        provider: :stripe,
        payment_type: :card,
        status: :active,
        is_default: account.payment_methods.active_methods.empty?,
        last_four: pm.card&.last4,
        brand: pm.card&.brand,
        expiry_month: pm.card&.exp_month,
        expiry_year: pm.card&.exp_year,
        external_id: pm.id
      )
    end
  end
end

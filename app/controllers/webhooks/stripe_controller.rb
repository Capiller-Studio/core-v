# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_stripe_signature

    def create
      return head(:bad_request) unless @event

      lock_key = format(::RedisUtilities::Keys::WEBHOOK_EVENT_LOCK, provider: "stripe", event_id: @event.id)

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          case @event.type
          when "payment_method.attached"
            handle_payment_method_attached(@event.data.object)
          when "charge.refunded"
            handle_charge_refunded(@event.data.object)
          when "charge.dispute.created"
            handle_charge_disputed(@event.data.object)
          when "payment_intent.payment_failed"
            handle_payment_failed_intent(@event.data.object)
          # -- Future/Deprecated Handlers --
          # when "checkout.session.completed"
          #   handle_checkout_completed(@event.data.object)
          # when "invoice.paid"
          #   handle_invoice_paid(@event.data.object)
          # when "invoice.payment_failed"
          #   handle_invoice_payment_failed(@event.data.object)
          # when "customer.subscription.updated"
          #   handle_subscription_updated(@event.data.object)
          # when "customer.subscription.deleted"
          #   handle_subscription_deleted(@event.data.object)
          # when "payment_intent.succeeded"
          #   handle_payment_intent_succeeded(@event.data.object)
          end
        end
      end

      head(:ok)
    rescue StandardError => e
      Rails.logger.error("Stripe webhook error: #{e.message}")
      head(:bad_request)
    end

    private

    # Reads the body once, constructs and verifies the event, and stores it in @event.
    # If verification fails, returns 401. The create action reads @event.
    def verify_stripe_signature
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook_secret)

      begin
        @event = ::Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError
        head(:bad_request)
      rescue ::Stripe::SignatureVerificationError
        head(:unauthorized)
      end
    end

    def handle_payment_method_attached(pm)
      # Use JSONB containment operator for proper PostgreSQL query
      account = Account.where("billing_data @> ?", { stripe_customer_id: pm.customer }.to_json).first
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

    def handle_charge_refunded(charge)
      Billing::RefundHandler.call(
        transaction_id: charge.id,
        payment_intent_id: charge.payment_intent
      )
    end

    def handle_charge_disputed(dispute)
      # dispute.charge is the charge ID
      Billing::DisputeHandler.call(
        transaction_id: dispute.charge,
        payment_intent_id: dispute.payment_intent
      )
    end

    def handle_payment_failed_intent(payment_intent)
      transaction = Transaction.find_by(external_id: payment_intent.id)
      return unless transaction

      transaction.fail!
    end

    # --- Commented Out Handlers (Not used due to custom wallet/billing architecture) ---
    #
    # def handle_payment_intent_succeeded(payment_intent)
    #   return unless payment_intent.metadata&.type == "wallet_topup"
    #   account = Account.find_by(id: payment_intent.metadata.account_id)
    #   return unless account
    #
    #   amount = payment_intent.amount / 100.0
    #   wallet = account.wallet
    #   wallet.credit!(amount, description: "wallet.events.topup", data: { stripe_payment_intent_id: payment_intent.id })
    #
    #   Transaction.create!(
    #     account:, transaction_type: :topup, status: :completed, amount: amount,
    #     currency: payment_intent.currency.upcase, provider: :stripe, external_id: payment_intent.id,
    #     description: "wallet.events.topup"
    #   )
    # end
    #
    # def handle_checkout_completed(session)
    #   # ... creates subscription
    # end
    #
    # def handle_invoice_paid(invoice)
    #   # ... handles stripe subscription invoice
    # end
    #
    # def handle_invoice_payment_failed(invoice)
    #   # ... marks past_due
    # end
    #
    # def handle_subscription_updated(stripe_sub)
    #   # ... syncs period dates
    # end
    #
    # def handle_subscription_deleted(stripe_sub)
    #   # ... cancels local subscription
    # end

  end
end

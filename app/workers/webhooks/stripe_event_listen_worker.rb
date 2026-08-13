# frozen_string_literal: true

module Webhooks
  class StripeEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        event = Stripe::Event.construct_from(webhook.payload)
        lock_key = format(::RedisUtilities::Keys::WEBHOOK_EVENT_LOCK, provider: "stripe", event_id: event.id)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ActiveRecord::Base.transaction do
            case event.type
            when "payment_method.attached"
              handle_payment_method_attached(event.data.object)
            when "charge.refunded"
              handle_charge_refunded(event.data.object)
            when "charge.dispute.created"
              handle_charge_disputed(event.data.object)
            when "payment_intent.payment_failed"
              handle_payment_failed_intent(event.data.object)
            end
          end
        end

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise(e)
      end
    end

    private

    def handle_payment_method_attached(pm)
      account = Account.where("billing_data @> ?", { stripe_customer_id: pm.customer }.to_json).first
      return unless account

      PaymentMethod.create!(
        account: account,
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
  end
end

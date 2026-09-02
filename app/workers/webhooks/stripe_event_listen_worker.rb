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
            when "payment_method.detached"
              handle_payment_method_detached(event.data.object)
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

    def find_account_from_object(obj)
      # 1. Direct metadata account_id
      account_id = (obj.respond_to?(:metadata) && obj.metadata ? obj.metadata["account_id"] : nil) ||
                   (obj.is_a?(Hash) ? obj.dig("metadata", "account_id") : nil)
      if account_id.present?
        account = Account.find_by(id: account_id)
        return account if account
      end

      # 2. Customer ID lookup via billing_data JSON
      customer_id = (obj.respond_to?(:customer) ? obj.customer : nil) ||
                    (obj.is_a?(Hash) ? obj["customer"] : nil)
      if customer_id.blank? && (obj.try(:object) == "customer" || (obj.is_a?(Hash) && obj["object"] == "customer"))
        customer_id = obj.respond_to?(:id) ? obj.id : obj["id"]
      end

      if customer_id.present?
        Account.where("billing_data @> ?", { stripe_customer_id: customer_id.to_s }.to_json).first
      end
    end

    def handle_payment_method_attached(pm)
      account = find_account_from_object(pm)
      return unless account

      existing = PaymentMethod.find_by(external_id: pm.id)
      return if existing

      is_first = account.payment_methods.active_methods.empty?
      PaymentMethod.create!(
        account: account,
        provider: :stripe,
        payment_type: :card,
        status: :active,
        default_method: is_first,
        last_four: pm.card&.last4,
        brand: pm.card&.brand,
        expiry_month: pm.card&.exp_month,
        expiry_year: pm.card&.exp_year,
        external_id: pm.id
      )
    end

    def handle_payment_method_detached(pm)
      record = PaymentMethod.find_by(external_id: pm.id)
      record&.update!(status: :removed)
    end

    def handle_charge_refunded(charge)
      payment_intent_id = charge.respond_to?(:payment_intent) ? charge.payment_intent : charge["payment_intent"]
      charge_id = charge.respond_to?(:id) ? charge.id : charge["id"]

      Billing::RefundHandler.call(
        transaction_id: charge_id,
        payment_intent_id: payment_intent_id
      )
    end

    def handle_charge_disputed(dispute)
      charge_id = dispute.respond_to?(:charge) ? dispute.charge : dispute["charge"]
      payment_intent_id = dispute.respond_to?(:payment_intent) ? dispute.payment_intent : dispute["payment_intent"]

      Billing::DisputeHandler.call(
        transaction_id: charge_id,
        payment_intent_id: payment_intent_id
      )
    end

    def handle_payment_failed_intent(payment_intent)
      transaction = Transaction.find_by(external_id: payment_intent.id)
      transaction&.fail!
    end
  end
end

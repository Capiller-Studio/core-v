# frozen_string_literal: true

module Billable
  extend ActiveSupport::Concern

  included do
    has_one :wallet, dependent: :destroy
    has_one :active_subscription, -> { where(status: [:active, :trialing]) }, class_name: "Subscription"
    has_many :subscriptions, dependent: :destroy
    has_many :payment_methods, dependent: :destroy
    has_many :transactions, dependent: :destroy
    has_many :invoices, dependent: :destroy

    after_create :create_wallet!
  end

  def current_plan
    active_subscription&.plan
  end

  def subscribed?
    active_subscription.present?
  end

  def trialing?
    active_subscription&.trialing?
  end

  def on_free_plan?
    !subscribed? || current_plan&.free?
  end

  def on_paid_plan?
    subscribed? && current_plan&.paid?
  end

  def wallet_balance
    wallet&.balance || 0
  end

  def default_payment_method
    payment_methods.default_method.first
  end

  # Track max agents for anti-gaming billing
  def track_agent_count!
    active_subscription&.record_agent_count(users_count)
  end

  private

  def create_wallet!
    Wallet.find_or_create_by!(account: self) do |w|
      w.currency = currency
    end
  end
end

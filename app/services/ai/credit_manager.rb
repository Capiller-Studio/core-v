# frozen_string_literal: true

module Ai
  class CreditManager < ApplicationService
    TRIAL_CREDIT_LIMIT = 50

    def initialize(account:, action_type:, model_used:, user: nil, cost: 1)
      @account = account
      @action_type = action_type
      @model_used = model_used
      @user = user
      @cost = cost
    end

    def call
      lock_key = "ai_credit_manager_#{@account.id}"
      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        raise AiInsufficientBalanceError, "AI credit balance is exhausted" unless can_afford?

        @account.ai_wallet.deduct!(
          @cost,
          action_type: @action_type,
          model_used: @model_used,
          user: @user,
          description: "billing.events.ai_action",
          data: { action_type: @action_type },
          force: in_trial_with_credits?
        )
      end
    end

    private

    def can_afford?
      return true if in_trial_with_credits?
      
      @account.ai_wallet.sufficient_balance?(@cost)
    end

    def in_trial_with_credits?
      subscription = @account.active_subscription
      return false unless subscription&.active_or_trialing?
      return false unless subscription.trialing?
      
      # In trial, they are allowed to go into negative balance up to -TRIAL_CREDIT_LIMIT
      @account.ai_wallet.balance - @cost >= -TRIAL_CREDIT_LIMIT
    end
    def self.refund!(account:, amount: 1, action_type: nil)
      account.ai_wallet.refund!(
        amount, 
        description: "billing.events.ai_refund",
        data: { action_type: action_type }
      )
    end
  end
end

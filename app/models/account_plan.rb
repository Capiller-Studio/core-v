# frozen_string_literal: true

class AccountPlan < ApplicationRecord
  belongs_to :account
  belongs_to :plan

  validates :account_id, uniqueness: { scope: :plan_id }
end

# frozen_string_literal: true

module Platform
  class Role < ApplicationRecord
    PERMISSION_SCHEMA = {
      "accounts" => %w[read manage],
      "users" => %w[read manage],
      "plans" => %w[read manage],
      "subscriptions" => %w[read manage],
      "transactions" => %w[read manage],
      "staff" => %w[read manage],
      "affiliates" => %w[read manage],
      "commissions" => %w[read manage],
      "referrals" => %w[read manage],
      "payouts" => %w[read manage],
      "payout_batches" => %w[read manage],
      "channels" => %w[read manage],
      "domains" => %w[read manage],
      "system_logs" => %w[read manage]
    }.freeze

    has_many :staff_roles, class_name: "Platform::StaffRole", dependent: :destroy
    has_many :staffs, through: :staff_roles

    validates :name, presence: true
    validates :identifier, presence: true, uniqueness: true

    def permissions_count
      permissions.keys.size
    end

    def super_admin?
      identifier == "super_admin"
    end

    def admin?
      super_admin? || identifier == "admin"
    end
  end
end

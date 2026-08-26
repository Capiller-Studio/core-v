# frozen_string_literal: true

class Plan < ApplicationRecord
  include Translateable

  TRANSLATABLE_FIELDS = %i[display_name description].freeze

  # Unique plan names for Deskbolic
  SYMBOLIC   = "symbolic"
  ANABOLIC   = "anabolic"
  HYPERBOLIC = "hyperbolic"
  PARABOLIC  = "parabolic"

  NAMES = [ SYMBOLIC, ANABOLIC, HYPERBOLIC, PARABOLIC ].freeze

  enum :status, { active: 0, archived: 1 }
  enum :visibility, { public_plan: 0, private_plan: 1 }

  has_many :subscriptions, dependent: :restrict_with_error
  has_many :account_plans, dependent: :destroy
  has_many :allowed_accounts, through: :account_plans, source: :account

  translates(*TRANSLATABLE_FIELDS)

  scope :available, -> { where(status: :active).order(:position) }
  scope :public_only, -> { where(visibility: :public_plan) }
  scope :private_only, -> { where(visibility: :private_plan) }
  scope :free, -> { where(base_price: 0) }
  scope :paid, -> { where("base_price > 0") }
  scope :available_for, ->(account) {
    if account.present?
      where(visibility: :public_plan).or(where(id: account.custom_plan_ids))
    else
      where(visibility: :public_plan)
    end
  }

  validates :name, presence: true, uniqueness: { scope: :currency }
  validates :currency, presence: true, inclusion: { in: Core::SUPPORTED_CURRENCIES }

  def free?
    base_price.zero?
  end

  def paid?
    !free?
  end

  def min_users
    limit_for(:users_min) == -1 ? 1 : limit_for(:users_min)
  end

  def max_users
    limit_for(:users_max)
  end

  # Limit helpers — returns -1 for unlimited
  def limit_for(resource)
    res = resource.to_s
    return limits[res] if limits.key?(res)
    return limits["users_max"] if res == "users" && limits.key?("users_max")

    -1
  end

  def unlimited?(resource)
    limit_for(resource) == -1
  end

  # Feature helpers — checks features jsonb
  def feature_enabled?(feature)
    keys = feature.to_s.split(".")
    if keys.size > 1
      features.dig(*keys) == true
    else
      features[feature.to_s] == true
    end
  end

  # Price for a given billing cycle
  def price_for(billing_cycle)
    case billing_cycle.to_s
    when "annual" then annual_price
    else base_price
    end
  end
end

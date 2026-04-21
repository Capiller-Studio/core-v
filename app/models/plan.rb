# frozen_string_literal: true

class Plan < ApplicationRecord
  include Translateable

  TRANSLATABLE_FIELDS = %i[display_name description].freeze

  # Unique plan names for Deskbolic
  STARTER    = "starter"
  MOMENTUM   = "momentum"
  PINNACLE   = "pinnacle"
  ENTERPRISE = "enterprise"

  NAMES = [STARTER, MOMENTUM, PINNACLE, ENTERPRISE].freeze

  enum :status, { active: 0, archived: 1 }

  has_many :subscriptions, dependent: :restrict_with_error

  translates(*TRANSLATABLE_FIELDS)

  scope :available, -> { where(status: :active).order(:position) }
  scope :free, -> { where(base_price: 0) }
  scope :paid, -> { where("base_price > 0") }

  validates :name, presence: true, uniqueness: true, inclusion: { in: NAMES }

  def free?
    base_price.zero?
  end

  def paid?
    !free?
  end

  def contact_us?
    contact_us
  end

  # Limit helpers — returns -1 for unlimited
  def limit_for(resource)
    limits[resource.to_s] || -1
  end

  def unlimited?(resource)
    limit_for(resource) == -1
  end

  # Feature helpers — checks configurations jsonb
  def feature_enabled?(feature)
    configurations[feature.to_s] == true
  end

  # Price for a given billing cycle
  def price_for(billing_cycle)
    case billing_cycle.to_s
    when "annual" then annual_price
    else base_price
    end
  end
end

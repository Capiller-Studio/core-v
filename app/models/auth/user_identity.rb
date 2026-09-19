# frozen_string_literal: true

module Auth
  class UserIdentity < ApplicationRecord
    belongs_to :user
    belongs_to :account, optional: true

    enum :provider, {
      google:   0,
      facebook: 1,
      github:   2,
      apple:    3,
      saml:     4,
      oidc:     5
    }

    validates :provider, presence: true
    validates :uid, presence: true, uniqueness: { scope: :provider }
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

    scope :for_enterprise, -> { where(provider: [:saml, :oidc]) }
    scope :for_social,     -> { where(provider: [:google, :facebook, :github, :apple]) }
    scope :recent,         -> { order(last_used_at: :desc) }

    def enterprise?
      saml? || oidc?
    end

    def social?
      !enterprise?
    end

    def touch_last_used!
      update_column(:last_used_at, Time.current)
    end
  end
end

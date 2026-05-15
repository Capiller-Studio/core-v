# frozen_string_literal: true

class AccountInvitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  has_secure_token :token

  enum :status, { pending: 0, accepted: 1, expired: 2, revoked: 3 }

  validates :email, presence: true, format: { with: Devise.email_regexp }
  validates :role_ids, presence: true
  validate :at_least_one_role
  validate :roles_must_belong_to_account, if: -> { new_record? || role_ids_changed? }

  before_validation :set_expiry, on: :create

  def expired?
    status == "expired" || (pending? && expires_at < Time.current)
  end

  private

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end

  def at_least_one_role
    return if role_ids.present? && role_ids.any?

    errors.add(:role_ids, :at_least_one)
  end

  def roles_must_belong_to_account
    return unless role_ids.present? && account_id.present?
    
    # We check roles in the account shard
    account.with_shard do
      valid_roles_count = Access::Role.where(id: role_ids, account_id: account_id).count
      if valid_roles_count != role_ids.size
        errors.add(:role_ids, :invalid_roles)
      end
    end
  end
end

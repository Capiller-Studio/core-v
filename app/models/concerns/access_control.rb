# frozen_string_literal: true

module AccessControl
  extend ActiveSupport::Concern

  included do
    # Link to the sharded roles through the join table
    has_many :account_user_roles, class_name: "Access::AccountUserRole", foreign_key: :account_user_id, dependent: :destroy, inverse_of: :account_user
    has_many :roles, through: :account_user_roles, class_name: "Access::Role"
  end

  def can?(permission_string, resource: nil)
    return true if owner?

    # 1. Split permission e.g., "conversations.read"
    resource_type, action = permission_string.split(".")

    active_roles = roles.to_a

    return false if active_roles.empty?

    # 3. Merge and check
    Access::PermissionMerger.call(active_roles.map(&:permissions), resource_type, action, resource)
  end
end

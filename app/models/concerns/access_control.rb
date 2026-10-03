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

  def assign_roles(new_role_ids)
    role_ids_to_set = Array(new_role_ids).compact_blank.map(&:to_s).uniq

    # If this account user is the owner, ensure the owner role is always retained
    if owner?
      owner_role = account.roles.find_by(identifier: "owner")
      role_ids_to_set << owner_role.id.to_s if owner_role && !role_ids_to_set.include?(owner_role.id.to_s)
    end

    account.with_shard do
      valid_role_ids = account.roles.where(id: role_ids_to_set).pluck(:id).map(&:to_s)
      existing_roles = Access::AccountUserRole.where(account_user_id: id).to_a
      existing_role_ids = existing_roles.map { |r| r.role_id.to_s }

      to_remove = existing_roles.select { |r| !valid_role_ids.include?(r.role_id.to_s) }
      to_remove.each(&:destroy)

      to_add = valid_role_ids - existing_role_ids
      to_add.each do |r_id|
        Access::AccountUserRole.create!(
          account: account,
          account_user_id: id,
          role_id: r_id
        )
      end
    end
    roles.reset
    account_user_roles.reset
    true
  end
end

# == Schema Information
#
# Table name: access_account_user_roles
#
#  id              :uuid             not null, primary key
#  account_id      :uuid             not null
#  account_user_id :uuid             not null
#  role_id         :uuid             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  idx_acc_user_role_composite                         (account_user_id,role_id)
#  index_access_account_user_roles_on_account_id       (account_id)
#  index_access_account_user_roles_on_account_user_id  (account_user_id)
#  index_access_account_user_roles_on_created_at       (created_at)
#  index_access_account_user_roles_on_role_id          (role_id)
#

# frozen_string_literal: true

module Access
  class AccountUserRole < ShardRecord
    belongs_to :account
    belongs_to :account_user
    belongs_to :role, class_name: "Access::Role"
  end
end

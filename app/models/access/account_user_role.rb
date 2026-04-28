# frozen_string_literal: true

module Access
  class AccountUserRole < ShardRecord
    belongs_to :account
    belongs_to :account_user
    belongs_to :role, class_name: "Access::Role"
  end
end

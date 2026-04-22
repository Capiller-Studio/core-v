# frozen_string_literal: true

module Access
  class AccountUserRole < ShardRecord
    belongs_to :account
    belongs_to :role, class_name: "Access::Role"

    validates :account_user_id, presence: true
  end
end

# frozen_string_literal: true

module Access
  class Role < ShardRecord
    include SlugGenerator.new(source: :name, column: :identifier, scope: :account_id)

    belongs_to :account
    has_many :account_user_roles, class_name: "Access::AccountUserRole", dependent: :destroy

    validates :name, presence: true
    validates :name, uniqueness: { scope: :account_id }

    # Example permissions structure:
    # {
    #   "conversation": { "read": true, "write": {"inbox_ids": ["uuid"]}, "delete": false },
    #   "settings": { "manage": true }
    # }
  end
end

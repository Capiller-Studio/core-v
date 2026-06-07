# frozen_string_literal: true

module Access
  class Role < ShardRecord
    include SlugGenerator.new(source: :name, column: :identifier, scope: :account_id)

    belongs_to :account
    has_many :account_user_roles, class_name: "Access::AccountUserRole", dependent: :destroy

    validates :name, presence: true
    validates :name, uniqueness: { scope: :account_id }

    scope :system_roles, -> { where(system_provided: true) }
    scope :custom_roles, -> { where(system_provided: false) }

    # Example permissions structure:
    # {
    #   "conversation": { "read": true, "write": {"inbox_ids": ["uuid"]}, "delete": false },
    #   "settings": { "manage": true }
    # }

    PERMISSION_SCHEMA = {
      "conversations" => ["read", "write", "delete"],
      "inboxes" => ["read", "write", "delete"],
      "teams" => ["read", "write", "delete"],
      "automations" => ["read", "manage"],
      "macros" => ["read", "manage", "execute"],
      "reports" => ["view", "export"],
      "settings" => ["manage"],
      "billing" => ["manage"],
      "roles" => ["read", "manage"],
      "agents" => ["read", "manage", "invite", "remove"],
      "email_templates" => ["read", "manage"],
      "assignment_policies" => ["read", "manage"],
      "skills" => ["read", "manage"],
      "identity_sources" => ["read", "manage"],
      "domains" => ["read", "manage"],
      "customers" => ["read", "write", "delete"],
      "labels" => ["read", "manage"],
      "custom_fields" => ["read", "manage"]
    }.freeze
  end
end

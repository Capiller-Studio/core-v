# frozen_string_literal: true

module Access
  class Role < ShardRecord
    include SlugGenerator.new(source: :name, column: :identifier, scope: :account_id)
    include UsageTrackable
    include Trackable

    belongs_to :account
    has_many :account_user_roles, class_name: "Access::AccountUserRole", dependent: :destroy

    validates :name, presence: true
    validates :name, uniqueness: { scope: :account_id }

    tracks_usage :custom_roles

    scope :system_roles, -> { where(system_provided: true) }
    scope :custom_roles, -> { where(system_provided: false) }

    public

    # Example permissions structure:
    # {
    #   "conversation": { "read": true, "write": {"inbox_ids": ["uuid"]}, "delete": false },
    #   "settings": { "manage": true }
    # }

    PERMISSION_SCHEMA = {
      "account" => ["manage"],
      "conversations" => ["read", "write", "delete", "manage"],
      "inboxes" => ["read", "write", "delete", "manage"],
      "teams" => ["read", "write", "delete", "manage"],
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
      "customers" => ["read", "write", "delete", "manage"],
      "labels" => ["read", "manage"],
      "custom_fields" => ["read", "manage"],
      "business_hours" => ["read", "manage"],
      "sla_policies" => ["read", "manage"],
      "csat_surveys" => ["read", "manage"],
      "integrations" => ["read", "manage"],
      "audit_logs" => ["read"],
      "help_center_portals" => ["manage"],
      "help_center_articles" => ["read", "manage"],
      "help_center_categories" => ["read", "manage"]
    }.freeze
  end
end

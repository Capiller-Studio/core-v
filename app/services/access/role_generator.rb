# frozen_string_literal: true

module Access
  class RoleGenerator < ApplicationService
    attr_accessor :account

    def initialize(account)
      self.account = account
    end

    def call
      account.with_shard do
        Access::Role.transaction do
          create_owner_role
          create_admin_role
          create_agent_role
        end
      end
    end

    private

    # The Owner role has full permissions — every resource, every action.
    # Assigned automatically to the first user during account creation.
    # Cannot be deleted or modified by users.
    def create_owner_role
      account.roles.find_or_create_by!(identifier: "owner") do |r|
        r.name = "Owner"
        r.system_provided = true
        r.permissions = Access::Role::PERMISSION_SCHEMA.transform_values do |actions|
          actions.index_with { |a| true }
        end
      end
    end

    def create_admin_role
      account.roles.find_or_create_by!(identifier: "administrator") do |r|
        r.name = "Administrator"
        r.system_provided = true
        r.permissions = {
          "account" => { "manage" => true },
          "conversations" => { "read" => true, "write" => true, "delete" => true },
          "inboxes" => { "read" => true, "write" => true, "delete" => true },
          "teams" => { "read" => true, "write" => true },
          "automations" => { "read" => true, "manage" => true },
          "macros" => { "read" => true, "manage" => true, "execute" => true },
          "reports" => { "view" => true, "export" => true },
          "settings" => { "manage" => true },
          "billing" => { "manage" => true },
          "agents" => { "read" => true, "manage" => true, "invite" => true, "remove" => true },
          "email_templates" => { "read" => true, "manage" => true },
          "assignment_policies" => { "read" => true, "manage" => true },
          "skills" => { "read" => true, "manage" => true },
          "identity_sources" => { "read" => true, "manage" => true },
          "domains" => { "read" => true, "manage" => true },
          "customers" => { "read" => true, "write" => true, "delete" => true },
          "labels" => { "read" => true, "manage" => true },
          "custom_fields" => { "read" => true, "manage" => true },
          "business_hours" => { "read" => true, "manage" => true },
          "sla_policies" => { "read" => true, "manage" => true },
          "csat_surveys" => { "read" => true, "manage" => true },
          "integrations" => { "read" => true, "manage" => true },
          "audit_logs" => { "read" => true },
          "help_center_portals" => { "manage" => true },
          "help_center_articles" => { "read" => true, "manage" => true },
          "help_center_categories" => { "read" => true, "manage" => true },
          "sso" => { "read" => true, "manage" => true }
        }
      end
    end

    def create_agent_role
      account.roles.find_or_create_by!(identifier: "agent") do |r|
        r.name = "Agent"
        r.system_provided = true
        r.permissions = {
          "conversations" => { "read" => true, "write" => true },
          "inboxes" => { "read" => true },
          "automations" => { "read" => true },
          "macros" => { "read" => true, "manage" => true, "execute" => true },
          "reports" => { "view" => true },
          "customers" => { "read" => true, "write" => true },
          "labels" => { "read" => true, "manage" => true },
          "help_center_articles" => { "read" => true },
          "help_center_categories" => { "read" => true }
        }
      end
    end
  end
end

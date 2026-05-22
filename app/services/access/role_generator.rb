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
        r.is_system = true
        r.permissions = {
          "conversations" => { "read" => true, "write" => true, "delete" => true },
          "inboxes" => { "read" => true, "write" => true, "delete" => true },
          "teams" => { "read" => true, "write" => true, "delete" => true },
          "automations" => { "read" => true, "manage" => true },
          "macros" => { "read" => true, "manage" => true, "execute" => true },
          "reports" => { "view" => true, "export" => true },
          "settings" => { "manage" => true },
          "billing" => { "manage" => true },
          "roles" => { "read" => true, "manage" => true },
          "agents" => { "read" => true, "manage" => true, "invite" => true, "remove" => true },
          "email_templates" => { "read" => true, "manage" => true }
        }
      end
    end

    def create_admin_role
      account.roles.find_or_create_by!(identifier: "administrator") do |r|
        r.name = "Administrator"
        r.is_system = true
        r.permissions = {
          "conversations" => { "read" => true, "write" => true, "delete" => true },
          "inboxes" => { "read" => true, "write" => true, "delete" => true },
          "teams" => { "read" => true, "write" => true },
          "automations" => { "read" => true, "manage" => true },
          "macros" => { "read" => true, "manage" => true, "execute" => true },
          "reports" => { "view" => true },
          "settings" => { "manage" => true },
          "billing" => { "manage" => true },
          "email_templates" => { "read" => true, "manage" => true }
        }
      end
    end

    def create_agent_role
      account.roles.find_or_create_by!(identifier: "agent") do |r|
        r.name = "Agent"
        r.is_system = true
        r.permissions = {
          "conversations" => { "read" => true, "write" => true },
          "inboxes" => { "read" => true },
          "automations" => { "read" => true },
          "macros" => { "read" => true, "manage" => true, "execute" => true },
          "reports" => { "view" => true }
        }
      end
    end
  end
end

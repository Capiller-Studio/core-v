# frozen_string_literal: true

module Access
  class RoleGenerator < ApplicationService
    def initialize(account)
      @account = account
    end

    def call
      Account.transaction do
        create_owner_role
        create_admin_role
        create_agent_role
      end
    end

    private

    # The Owner role has full permissions — every resource, every action.
    # Assigned automatically to the first user during account creation.
    # Cannot be deleted or modified by users.
    def create_owner_role
      @account.roles.find_or_create_by!(name: "Owner") do |r|
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
          "agents" => { "read" => true, "manage" => true, "invite" => true, "remove" => true }
        }
      end
    end

    def create_admin_role
      @account.roles.find_or_create_by!(name: "Administrator") do |r|
        r.is_system = true
        r.permissions = {
          "conversations" => { "read" => true, "write" => true, "delete" => true },
          "inboxes" => { "read" => true, "write" => true, "delete" => true },
          "teams" => { "read" => true, "write" => true },
          "automations" => { "read" => true, "manage" => true },
          "macros" => { "read" => true, "manage" => true, "execute" => true },
          "reports" => { "view" => true },
          "settings" => { "manage" => true },
          "billing" => { "manage" => true }
        }
      end
    end

    def create_agent_role
      @account.roles.find_or_create_by!(name: "Agent") do |r|
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

# frozen_string_literal: true

module Access
  class RoleGenerator < ApplicationService
    def initialize(account)
      @account = account
    end

    def call
      Account.transaction do
        create_admin_role
        create_agent_role
      end
    end

    private

    def create_admin_role
      @account.roles.find_or_create_by!(name: "Administrator") do |r|
        r.is_system = true
        r.permissions = {
          "conversations" => { "read" => true, "write" => true, "delete" => true },
          "inboxes" => { "read" => true, "write" => true, "delete" => true },
          "teams" => { "read" => true, "write" => true },
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
          "reports" => { "view" => true }
        }
      end
    end
  end
end

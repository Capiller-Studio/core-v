# frozen_string_literal: true

module Platform
  class PermissionService
    def self.can?(staff, resource, action)
      new(staff).can?(resource, action)
    end

    def initialize(staff)
      @staff = staff
    end

    def can?(resource, action)
      return false unless @staff&.active?
      return true if super_admin?

      merged_permissions.dig(resource.to_s, action.to_s) == true
    end

    private

    def super_admin?
      @super_admin ||= @staff.roles.exists?(identifier: "super_admin")
    end

    def merged_permissions
      @merged_permissions ||= begin
        result = {}
        @staff.roles.each do |role|
          role.permissions.each do |res, actions|
            result[res] ||= {}
            actions.each do |act, allowed|
              result[res][act] = true if allowed == true
            end
          end
        end
        result
      end
    end
  end
end

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

      res = resource.to_s
      act = action.to_s

      # 'manage' permission implies all actions including 'read'
      return true if merged_permissions.dig(res, "manage") == true
      return true if merged_permissions.dig(res, act) == true

      false
    end

    private

    def super_admin?
      @super_admin ||= @staff.roles.exists?(identifier: "super_admin")
    end

    def merged_permissions
      @merged_permissions ||= begin
        result = {}
        @staff.roles.each do |role|
          next unless role.permissions.is_a?(Hash)

          role.permissions.each do |res, actions|
            result[res.to_s] ||= {}
            if actions.is_a?(Array)
              actions.each { |a| result[res.to_s][a.to_s] = true }
            elsif actions.is_a?(Hash)
              actions.each do |a, allowed|
                result[res.to_s][a.to_s] = true if allowed == true || allowed == "true"
              end
            end
          end
        end
        result
      end
    end
  end
end

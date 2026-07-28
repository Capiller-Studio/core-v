# frozen_string_literal: true

module Seeds
  class AdminSeeder
    DEFAULT_EMAIL = "ahsan@techbolic.com"
    DEFAULT_PASSWORD = "ChangeMe123#"
    DEFAULT_NAME = "Platform Admin"

    def self.seed(...)
      new(...).seed
    end

    def initialize(email: DEFAULT_EMAIL, password: DEFAULT_PASSWORD, name: DEFAULT_NAME)
      @email = email
      @password = password
      @name = name
    end

    def seed
      staff = Platform::Staff.transaction do
        super_admin_role = create_super_admin_role
        seeded_staff = seed_admin_staff!
        assign_super_admin_role!(seeded_staff, super_admin_role)
        seeded_staff
      end

      puts "Admin seeder ran successfully: #{staff.email} / roles: #{staff.roles.pluck(:identifier).join(', ')}"
      staff
    end

    private

    attr_reader :email, :password, :name

    # The Super Admin role has full permissions — every resource, every action.
    def create_super_admin_role
      Platform::Role.find_or_create_by!(identifier: "super_admin") do |r|
        r.name = "Super Admin"
        r.permissions = Platform::Role::PERMISSION_SCHEMA.transform_values do |actions|
          actions.index_with(true)
        end
      end
    end

    def seed_admin_staff!
      staff = Platform::Staff.find_or_initialize_by(email: email)
      staff.name = name
      staff.status = :active

      if staff.new_record?
        staff.password = password
        staff.password_confirmation = password
      end

      staff.save!
      staff
    end

    def assign_super_admin_role!(staff, super_admin_role)
      staff.staff_roles.where.not(role_id: super_admin_role.id).destroy_all
      staff.staff_roles.find_or_create_by!(role: super_admin_role)
      staff.roles.reload
    end
  end
end

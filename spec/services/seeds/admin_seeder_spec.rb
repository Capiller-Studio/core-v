require "rails_helper"

RSpec.describe Seeds::AdminSeeder do
  subject(:seed_admin) do
    described_class.seed(email: email, password: password, name: name)
  end

  let(:email) { "platform-admin@example.com" }
  let(:password) { "SecurePassword123!" }
  let(:name) { "Platform Admin" }

  describe ".seed" do
    it "persists the super admin role assignment" do
      staff = seed_admin
      super_admin_role = Platform::Role.find_by!(identifier: "super_admin")

      expect(staff).to be_persisted
      expect(Platform::StaffRole).to exist(staff: staff, role: super_admin_role)
      expect(staff.roles.reload.pluck(:identifier)).to contain_exactly("super_admin")
    end

    it "creates only the super admin role" do
      staff = seed_admin

      expect(Platform::Role.pluck(:identifier)).to contain_exactly("super_admin")
      expect(staff.roles.reload.pluck(:identifier)).to contain_exactly("super_admin")
    end

    it "does not create another admin when run again" do
      first_staff = seed_admin
      staff_count = Platform::Staff.count
      second_staff = nil

      expect do
        second_staff = described_class.seed(email: email, password: password, name: name)
      end.to output("Admin seeder ran successfully: #{email} / roles: super_admin\n").to_stdout

      expect(second_staff.id).to eq(first_staff.id)
      expect(Platform::Staff.count).to eq(staff_count)
      expect(Platform::Staff.where(email: email).count).to eq(1)
    end

    it "removes other assignments and remains idempotent" do
      staff = seed_admin
      billing_role = Platform::Role.create!(
        identifier: "billing_admin",
        name: "Billing Admin",
        permissions: {}
      )
      Platform::StaffRole.create!(staff: staff, role: billing_role)

      2.times do
        described_class.seed(email: email, password: password, name: name)
      end

      expect(staff.staff_roles.reload.size).to eq(1)
      expect(staff.roles.reload.pluck(:identifier)).to contain_exactly("super_admin")
    end

    it "builds super admin permissions from the platform permission schema" do
      seed_admin
      expected_permissions = Platform::Role::PERMISSION_SCHEMA.transform_values do |actions|
        actions.index_with(true)
      end

      expect(Platform::Role.find_by!(identifier: "super_admin").permissions).to eq(expected_permissions)
    end

  end
end

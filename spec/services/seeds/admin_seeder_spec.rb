# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seeds::AdminSeeder do
  subject(:seed_admin) do
    described_class.seed(email: email, password: password, name: name)
  end

  let(:email) { "ahsan@techbolic.com" }
  let(:password) { "SecurePassword123!" }
  let(:name) { "Ahsan" }

  describe ".seed" do
    it "persists the super admin role assignment and standard roles" do
      staff = seed_admin
      super_admin_role = Platform::Role.find_by!(identifier: "super_admin")

      expect(staff).to be_persisted
      expect(Platform::StaffRole).to exist(staff: staff, role: super_admin_role)
      expect(staff.roles.reload.pluck(:identifier)).to contain_exactly("super_admin")
    end

    it "creates all standard roles defined in the seeder" do
      seed_admin

      expected_identifiers = %w[super_admin admin finance support affiliate_manager read_only]
      expect(Platform::Role.pluck(:identifier)).to match_array(expected_identifiers)
    end

    it "does not create another admin when run again" do
      first_staff = seed_admin
      staff_count = Platform::Staff.count
      user_count = User.count
      second_staff = nil

      expect do
        second_staff = described_class.seed(email: email, password: password, name: name)
      end.to output(/Admin seeder ran successfully: staff=#{Regexp.escape(email)} user=#{Regexp.escape(email)} \/ roles: super_admin\n/).to_stdout

      expect(second_staff.id).to eq(first_staff.id)
      expect(Platform::Staff.count).to eq(staff_count)
      expect(Platform::Staff.where(email: email).count).to eq(1)
      expect(User.count).to eq(user_count)
      expect(User.where("LOWER(email) = ?", email.downcase).count).to eq(1)
    end

    it "creates a confirmed dashboard User that can authenticate" do
      seed_admin

      user = User.find_by!("LOWER(email) = ?", email.downcase)
      expect(user).to be_persisted
      expect(user.confirmed_at).to be_present
      expect(user.valid_password?(password)).to be(true)
      expect(user.accounts.count).to be >= 1
    end

    it "updates the dashboard User password when re-seeded" do
      seed_admin
      new_password = "AnotherSecure99!"

      described_class.seed(email: email, password: new_password, name: name)

      user = User.find_by!("LOWER(email) = ?", email.downcase)
      expect(user.valid_password?(new_password)).to be(true)
    end

    it "removes other assignments and remains idempotent" do
      staff = seed_admin
      custom_role = Platform::Role.create!(
        identifier: "custom_role",
        name: "Custom Role",
        permissions: {}
      )
      Platform::StaffRole.create!(staff: staff, role: custom_role)

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

    it "builds read_only permissions with only read access" do
      seed_admin
      expected_permissions = Platform::Role::PERMISSION_SCHEMA.transform_values do |actions|
        actions.index_with { |action| action == "read" }
      end

      expect(Platform::Role.find_by!(identifier: "read_only").permissions).to eq(expected_permissions)
    end
  end
end

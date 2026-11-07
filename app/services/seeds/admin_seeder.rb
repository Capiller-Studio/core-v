# frozen_string_literal: true

module Seeds
  class AdminSeeder
    DEFAULT_EMAIL = ENV.fetch("ADMIN_DEFAULT_EMAIL", "ahsan@techbolic.com")
    DEFAULT_PASSWORD = ENV.fetch("ADMIN_DEFAULT_PASSWORD", "ChangeMe123#")
    DEFAULT_NAME = ENV.fetch("ADMIN_DEFAULT_NAME", "Ahsan")

    STANDARD_ROLES = {
      "super_admin" => {
        name: "Super Admin",
        permissions: :all_manage
      },
      "admin" => {
        name: "Administrator",
        permissions: {
          "accounts" => %w[read manage],
          "users" => %w[read manage],
          "plans" => %w[read manage],
          "subscriptions" => %w[read manage],
          "transactions" => %w[read manage],
          "staff" => %w[read],
          "affiliates" => %w[read manage],
          "commissions" => %w[read manage],
          "referrals" => %w[read manage],
          "payouts" => %w[read manage],
          "payout_batches" => %w[read manage],
          "channels" => %w[read manage],
          "domains" => %w[read manage],
          "system_logs" => %w[read manage]
        }
      },
      "finance" => {
        name: "Finance & Billing",
        permissions: {
          "accounts" => %w[read],
          "users" => %w[read],
          "plans" => %w[read manage],
          "subscriptions" => %w[read manage],
          "transactions" => %w[read manage],
          "affiliates" => %w[read],
          "commissions" => %w[read manage],
          "referrals" => %w[read],
          "payouts" => %w[read manage],
          "payout_batches" => %w[read manage],
          "system_logs" => %w[read]
        }
      },
      "support" => {
        name: "Support Lead",
        permissions: {
          "accounts" => %w[read manage],
          "users" => %w[read manage],
          "plans" => %w[read],
          "subscriptions" => %w[read],
          "transactions" => %w[read],
          "channels" => %w[read manage],
          "domains" => %w[read manage],
          "system_logs" => %w[read]
        }
      },
      "affiliate_manager" => {
        name: "Affiliate Manager",
        permissions: {
          "accounts" => %w[read],
          "users" => %w[read],
          "affiliates" => %w[read manage],
          "commissions" => %w[read manage],
          "referrals" => %w[read manage],
          "payouts" => %w[read manage],
          "payout_batches" => %w[read manage]
        }
      },
      "read_only" => {
        name: "Auditor",
        permissions: :all_read
      }
    }.freeze

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
        seed_roles!
        super_admin_role = Platform::Role.find_by!(identifier: "super_admin")
        seeded_staff = seed_admin_staff!
        assign_super_admin_role!(seeded_staff, super_admin_role)
        seeded_staff
      end

      user = seed_dashboard_user!
      puts "Admin seeder ran successfully: staff=#{staff.email} user=#{user.email} / roles: #{staff.roles.pluck(:identifier).join(', ')}"
      staff
    end

    private

    attr_reader :email, :password, :name

    def seed_roles!
      STANDARD_ROLES.each do |identifier, config|
        role = Platform::Role.find_or_initialize_by(identifier: identifier)
        role.name = config[:name]
        role.permissions = build_permissions_hash(config[:permissions])
        role.save!
      end
    end

    def build_permissions_hash(rule)
      Platform::Role::PERMISSION_SCHEMA.to_h do |resource, actions|
        permissions = actions.index_with do |action|
          case rule
          when :all_manage
            true
          when :all_read
            action == "read"
          when Hash
            rule[resource]&.include?(action) || false
          else
            false
          end
        end
        [resource, permissions]
      end
    end

    def seed_admin_staff!
      staff = Platform::Staff.find_or_initialize_by(email: email)
      staff.name = name
      staff.status = :active
      staff.password = password
      staff.password_confirmation = password
      staff.save!
      staff
    end

    # /login authenticates User, not Platform::Staff. Keep staff for platform roles,
    # and always upsert a confirmed dashboard owner from ADMIN_DEFAULT_*.
    def seed_dashboard_user!
      existing = User.find_by("LOWER(email) = ?", email.downcase)
      if existing
        existing.password = password
        existing.password_confirmation = password
        existing.confirmed_at ||= Time.current
        existing.confirmation_token = nil
        existing.locked_at = nil
        existing.failed_attempts = 0
        existing.save!
        return existing
      end

      first_name, last_name = name.to_s.split(/\s+/, 2)
      result = Accounts::RegistrationService.call(
        email: email,
        password: password,
        first_name: first_name.presence || "Admin",
        last_name: last_name.presence || "User",
        account_name: ENV.fetch("ADMIN_DEFAULT_ACCOUNT_NAME", "Capiller Rely"),
        locale: "en",
        currency: ENV.fetch("ADMIN_DEFAULT_CURRENCY", "INR"),
        shard_key: "de"
      )
      raise "Dashboard admin seed failed: #{result.errors.inspect}" unless result.success?

      user = result.user
      user.confirmed_at ||= Time.current
      user.confirmation_token = nil
      user.locked_at = nil
      user.failed_attempts = 0
      user.save!
      user
    end

    def assign_super_admin_role!(staff, super_admin_role)
      staff.staff_roles.where.not(role_id: super_admin_role.id).destroy_all
      staff.staff_roles.find_or_create_by!(role: super_admin_role)
      staff.roles.reload
    end
  end
end

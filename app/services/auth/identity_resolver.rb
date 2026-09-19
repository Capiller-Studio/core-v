# frozen_string_literal: true

module Auth
  class IdentityResolver < ApplicationService
    ResolverResult = Struct.new(
      :success,
      :user,
      :identity,
      :provisioned,
      :error_code,
      :error_message,
      keyword_init: true
    ) do
      def success?
        success == true
      end

      def failure?
        !success?
      end

      def provisioned?
        provisioned == true
      end
    end

    attr_reader :provider, :uid, :email, :account, :first_name, :last_name,
                :credentials, :extra_attributes

    def initialize(provider:, uid:, email:, account: nil, first_name: nil, last_name: nil, credentials: {}, extra_attributes: {})
      @provider         = provider.to_s
      @uid              = uid.to_s.strip
      @email            = email&.to_s&.strip&.downcase
      @account          = account
      @first_name       = first_name&.to_s&.strip
      @last_name        = last_name&.to_s&.strip
      @credentials      = credentials || {}
      @extra_attributes = extra_attributes || {}
    end

    def call
      return failure_result("missing_credentials", "Provider and UID are required") if provider.blank? || uid.blank?

      # 1. Existing identity lookup
      identity = Auth::UserIdentity.find_by(provider: provider, uid: uid)
      if identity.present?
        identity.touch_last_used!
        user = identity.user
        ensure_account_membership(user) if account.present?
        return success_result(user: user, identity: identity, provisioned: false)
      end

      # 2. Existing user lookup by email
      if email.present?
        user = User.find_by(email: email)
        if user.present?
          identity = link_identity_to_user!(user)
          ensure_account_membership(user) if account.present?
          audit_identity_linked(user)
          return success_result(user: user, identity: identity, provisioned: false)
        end
      end

      # 3. JIT Provisioning (New User)
      return failure_result("jit_disabled", "Just-in-Time provisioning is disabled for this organization") unless jit_enabled?

      user, identity = jit_provision_user!
      success_result(user: user, identity: identity, provisioned: true)
    rescue StandardError => e
      Rails.logger.error("Auth::IdentityResolver failed: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      failure_result("resolution_error", e.message)
    end

    private

    def success_result(user:, identity:, provisioned:)
      ResolverResult.new(
        success:       true,
        user:          user,
        identity:      identity,
        provisioned:   provisioned,
        error_code:    nil,
        error_message: nil
      )
    end

    def failure_result(code, message)
      ResolverResult.new(
        success:       false,
        user:          nil,
        identity:      nil,
        provisioned:   false,
        error_code:    code,
        error_message: message
      )
    end

    def jit_enabled?
      return true if account.blank? # Social login without tenant restriction

      sso_config&.jit_provisioning_enabled? != false
    end

    def sso_config
      @sso_config ||= account&.sso_configuration
    end

    def link_identity_to_user!(user)
      Auth::UserIdentity.create!(
        user:             user,
        account:          account,
        provider:         provider,
        uid:              uid,
        email:            email,
        credentials:      credentials,
        extra_attributes: extra_attributes,
        last_used_at:     Time.current
      )
    end

    def ensure_account_membership(user)
      return if account.blank?

      account_user = AccountUser.find_by(account: account, user: user)
      return account_user if account_user.present?

      account_user = AccountUser.create!(
        account: account,
        user:    user,
        owner:   false,
        status:  :active
      )

      assign_shard_role(account_user)
      account_user
    end

    def jit_provision_user!
      account_user = nil
      user = nil
      identity = nil

      # Primary DB write transaction
      ActiveRecord::Base.transaction do
        full_name = [first_name, last_name].compact.join(" ").presence || email.to_s.split("@").first
        address = Address.create!(name: full_name)

        user = User.new(
          email:        email,
          first_name:   first_name.presence || email.to_s.split("@").first,
          last_name:    last_name,
          address:      address,
          password:     SecureRandom.hex(32),
          confirmed_at: Time.current
        )
        user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
        user.save!

        identity = Auth::UserIdentity.create!(
          user:             user,
          account:          account,
          provider:         provider,
          uid:              uid,
          email:            email,
          credentials:      credentials,
          extra_attributes: extra_attributes,
          last_used_at:     Time.current
        )

        if account.present?
          account_user = AccountUser.create!(
            account: account,
            user:    user,
            owner:   false,
            status:  :active
          )
        end
      end

      # Shard DB write (outside primary transaction)
      if account.present? && account_user.present?
        assign_shard_role(account_user)
      end

      # Primary DB audit log
      Auth::AuditLog.log(
        event_type:  :jit_user_created,
        auth_method: provider.to_sym,
        status:      :success,
        account:     account,
        user:        user,
        email:       email,
        metadata:    { provider: provider, uid: uid }
      )

      [user, identity]
    end

    def assign_shard_role(account_user)
      return if account.blank?

      role_id_to_assign = sso_config&.default_role_id

      account.with_shard do
        role_id_to_assign ||= Access::Role.find_by(account_id: account.id, identifier: "agent")&.id

        if role_id_to_assign.present?
          Access::AccountUserRole.find_or_create_by!(
            account:      account,
            account_user: account_user,
            role_id:      role_id_to_assign
          )
        end
      rescue StandardError => e
        Rails.logger.warn("Auth::IdentityResolver failed to assign shard role: #{e.message}")
      end
    end

    def audit_identity_linked(user)
      Auth::AuditLog.log(
        event_type:  :identity_linked,
        auth_method: provider.to_sym,
        status:      :success,
        account:     account,
        user:        user,
        email:       email,
        metadata:    { provider: provider, uid: uid }
      )
    end
  end
end

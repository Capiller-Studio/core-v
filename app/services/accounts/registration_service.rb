# frozen_string_literal: true

module Accounts
  class RegistrationService < ApplicationService
    Result = Struct.new(:success?, :user, :account, :errors, keyword_init: true)

    attr_reader :params

    def initialize(**params)
      @params = params
    end

    def call
      user = nil
      account = nil

      ActiveRecord::Base.transaction do
        user = create_user!

        if params[:as_affiliate]
          create_affiliate_profile!(user)
        end

        if params[:account_name].present?
          account = create_account_with_owner!(user)
        elsif params[:invitation_token].present?
          account = accept_invitation!(user, params[:invitation_token])
        end
      end

      Result.new(success?: true, user: user, account: account, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, user: nil, account: nil, errors: format_errors(e.record))
    end

    private

    def create_user!
      User.create!(
        email: params[:email],
        password: params[:password],
        first_name: params[:first_name],
        last_name: params[:last_name],
        address: Address.create!,
        confirmed_at: Time.current
      )
    end

    def create_affiliate_profile!(user)
      user.create_affiliate_profile!
    end

    def create_account_with_owner!(user)
      account = Account.create!(
        name: params[:account_name],
        email: user.email
      )

      account_user = AccountUser.create!(
        account: account,
        user: user,
        role: :owner
      )

      # Assign the Owner Access::Role to the owner user.
      # RoleGenerator runs via Account.after_create and creates Owner/Administrator/Agent roles.
      # We wire the owner to the "Owner" role here so the JSONB permission system is connected.
      assign_owner_role!(account, account_user)

      account
    end

    def assign_owner_role!(account, account_user)
      owner_role = account.roles.find_by!(name: "Owner")

      Access::AccountUserRole.create!(
        account: account,
        account_user_id: account_user.id,
        role: owner_role
      )
    end

    def accept_invitation!(user, token)
      # TODO: Implement invitation redemption
      # Expected flow:
      #   1. Find invitation by token
      #   2. Validate it hasn't expired
      #   3. Create AccountUser with the invited role
      #   4. Mark invitation as accepted
      nil
    end

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.full_message }
      end
    end
  end
end

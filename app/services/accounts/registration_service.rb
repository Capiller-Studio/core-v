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
      user_attrs = {
        email: params[:email],
        password: params[:password],
        first_name: params[:first_name],
        last_name: params[:last_name],
        locale: params[:user_locale] || "en"
      }

      if params[:country].present?
        user_attrs[:address] = Address.create!(country_id: Country.find_by(iso: params[:country])&.id)
      else
        user_attrs[:address] = Address.create!
      end

      user = User.new(user_attrs)
      if params[:invitation_token].present?
        user.skip_confirmation!
      end

      user.save!
      user
    end

    def create_affiliate_profile!(user)
      if params[:currency].present?
        user.create_affiliate_profile!(currency: params[:currency])
      else
        user.create_affiliate_profile!
      end
    end

    def create_account_with_owner!(user)
      account = Account.create!(
        name: params[:account_name],
        email: user.email,
        locale: params[:locale] || "en",
        currency: params[:currency] || "USD",
        shard_key: params[:shard_key] || "de"
      )

      account_user = AccountUser.create!(
        account: account,
        user: user,
        owner: true
      )

      # Assign the Owner Access::Role to the owner user.
      # RoleGenerator runs via Account.after_create and creates Owner/Administrator/Agent roles.
      # We wire the owner to the "Owner" role here so the JSONB permission system is connected.
      assign_owner_role!(account, account_user)

      account
    end

    def assign_owner_role!(account, account_user)
      owner_role = account.roles.find_by!(identifier: "owner")

      Access::AccountUserRole.create!(
        account: account,
        account_user_id: account_user.id,
        role: owner_role
      )
    end

    def accept_invitation!(user, token)
      invitation = AccountInvitation.find_by!(token: token)
      if invitation.expired?
        raise ActiveRecord::RecordInvalid, invitation.tap { |i| i.errors.add(:base, :expired) }
      end

      account = invitation.account
      account_user = AccountUser.create!(
        account: account,
        user: user,
        owner: false
      )

      account.with_shard do
        invitation.role_ids.each do |role_id|
          Access::AccountUserRole.create!(
            account: account,
            account_user_id: account_user.id,
            role_id: role_id
          )
        end
      end

      invitation.update!(status: :accepted)
      account
    end

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.full_message }
      end
    end
  end
end

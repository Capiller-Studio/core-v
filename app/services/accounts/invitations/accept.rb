# frozen_string_literal: true

module Accounts
  module Invitations
    class Accept < ApplicationService
      attr_accessor :token, :user, :invitation, :account

      def initialize(token:, user:)
        self.token = token
        self.user = user
      end

      def call
        find_and_validate_invitation
        
        ActiveRecord::Base.transaction do
          create_account_user
          assign_roles_in_shard
          mark_invitation_accepted
        end

        invitation
      end

      private

      def find_and_validate_invitation
        self.invitation = AccountInvitation.find_by!(token: token)
        self.account = invitation.account

        if !invitation.pending?
          error_key = invitation.accepted? ? "already_accepted" : "expired"
          raise StandardError, I18n.t("accounts.invitations.errors.#{error_key}")
        elsif invitation.expired?
          raise StandardError, I18n.t("accounts.invitations.errors.expired")
        end
      end

      def create_account_user
        # AccountUser is in the primary database
        # We use find_or_create_by! to handle race conditions where a user might be 
        # manually added to the account while the invitation is being accepted.
        account.account_users.find_or_create_by!(user: user) do |au|
          au.invited_by = invitation.invited_by
        end
      end

      def assign_roles_in_shard
        # Access::AccountUserRole and Access::Role are in the shard
        account_user = account.account_users.find_by!(user: user)
        
        account.with_shard do
          # Filter only roles that still exist in the account
          active_role_ids = Access::Role.where(id: invitation.role_ids, account_id: account.id).pluck(:id)
          
          if active_role_ids.empty?
            # If all invited roles were deleted, we attempt to find a default "agent" role
            default_role = Access::Role.find_by(account_id: account.id, identifier: "agent")
            
            if default_role
              active_role_ids = [default_role.id]
            else
              # If even the default role is missing, we must fail to satisfy "must have at least one role"
              raise StandardError, I18n.t("accounts.invitations.errors.no_valid_roles")
            end
          end

          active_role_ids.each do |role_id|
            Access::AccountUserRole.create!(
              account: account,
              account_user_id: account_user.id,
              role_id: role_id
            )
          end
        end
      end

      def mark_invitation_accepted
        invitation.update!(status: :accepted)
      end
    end
  end
end

# frozen_string_literal: true

module Accounts
  module Invitations
    class Create < ApplicationService
      attr_accessor :account, :invited_by, :email, :role_ids, :invitation

      def initialize(account:, invited_by:, email:, role_ids:)
        self.account = account
        self.invited_by = invited_by
        self.email = email.to_s.downcase.strip
        self.role_ids = role_ids
      end

      def call
        validate_not_already_member
        revoke_existing_invitations
        create_invitation
        deliver_email
        
        invitation
      end

      private

      def validate_not_already_member
        user = User.find_by(email: email)
        if user && account.users.exists?(id: user.id)
          raise(StandardError, I18n.t("accounts.invitations.errors.already_member"))
        end
      end

      def revoke_existing_invitations
        # rubocop:disable Rails/SkipsModelValidations
        account.account_invitations.pending.where(email: email).update_all(status: :revoked)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def create_invitation
        self.invitation = account.account_invitations.create!(
          email: email,
          role_ids: role_ids,
          invited_by: invited_by
        )
      end

      def deliver_email
        AccountInvitationMailer.with(invitation: invitation).invite.deliver_later
      end
    end
  end
end

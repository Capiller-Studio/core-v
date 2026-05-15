# frozen_string_literal: true

class AccountInvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @account = @invitation.account
    @inviter = @invitation.invited_by
    
    # We fetch roles from the shard to show names in the email
    @role_names = @account.with_shard do
      Access::Role.where(id: @invitation.role_ids).pluck(:name)
    end

    I18n.with_locale(@account.locale) do
      mail(
        to: @invitation.email,
        subject: I18n.t("mailers.account_invitation.invite.subject", account_name: @account.name)
      )
    end
  end
end

require 'rails_helper'

RSpec.describe Accounts::Invitations::Create do
  let(:account) { create(:account) }
  let(:invited_by) { create(:user) }
  let(:email) { 'New_User@example.com ' }
  let(:role_ids) { [account.roles.find_by!(identifier: 'agent').id] }
  let(:service) { described_class.new(account: account, invited_by: invited_by, email: email, role_ids: role_ids) }

  describe '#call' do
    context 'when the user is not already a member' do
      it 'revokes existing invitations, creates a new one, and sends an email' do
        # Create an existing pending invitation
        existing_invitation = create(:account_invitation, account: account, email: 'new_user@example.com', role_ids: role_ids)
        
        mailer_double = instance_double(ActionMailer::MessageDelivery)
        allow(AccountInvitationMailer).to receive(:with).and_return(double(invite: mailer_double))
        allow(mailer_double).to receive(:deliver_later)

        result = nil
        expect {
          result = service.call
        }.to change(AccountInvitation, :count).by(1)

        expect(existing_invitation.reload.status).to eq('revoked')
        expect(result.email).to eq('new_user@example.com')
        expect(result.role_ids).to eq(role_ids)
        expect(result.invited_by).to eq(invited_by)
        
        expect(AccountInvitationMailer).to have_received(:with).with(invitation: result)
        expect(mailer_double).to have_received(:deliver_later)
      end
    end

    context 'when the user is already a member of the account' do
      it 'raises an error' do
        existing_user = create(:user, email: 'new_user@example.com')
        create(:account_user, user: existing_user, account: account)
        
        expect { service.call }.to raise_error(StandardError, I18n.t("accounts.invitations.errors.already_member"))
      end
    end
  end
end

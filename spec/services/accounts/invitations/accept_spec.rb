require 'rails_helper'

RSpec.describe Accounts::Invitations::Accept do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:invited_by) { create(:user) }
  let(:role) { account.roles.find_by!(identifier: 'agent') }
  let(:invitation) { create(:account_invitation, account: account, role_ids: [role.id], invited_by: invited_by) }
  let(:service) { described_class.new(token: invitation.token, user: user) }

  describe '#call' do
    context 'with a valid invitation' do
      it 'creates an account user, assigns roles, and marks as accepted' do
        result = nil
        expect {
          result = service.call
        }.to change(AccountUser, :count).by(1)
         .and change(Access::AccountUserRole, :count).by(1)

        expect(result).to eq(invitation)
        
        account_user = AccountUser.last
        expect(account_user.user).to eq(user)
        expect(account_user.account).to eq(account)
        expect(account_user.invited_by).to eq(invited_by)

        expect(invitation.reload.status).to eq('accepted')
      end
    end

    context 'when the invited role no longer exists' do
      it 'falls back to the default agent role' do
        deleted_role_id = SecureRandom.uuid
        # rubocop:disable Rails/SkipsModelValidations
        invitation.update_column(:role_ids, [deleted_role_id])
        # rubocop:enable Rails/SkipsModelValidations
        
        # Ensure default agent role exists
        agent_role = account.roles.find_by!(identifier: 'agent')
        
        service.call
        
        account_user = AccountUser.find_by(user: user, account: account)
        assigned_role = Access::AccountUserRole.find_by(account_user_id: account_user.id).role
        expect(assigned_role).to eq(agent_role)
      end

      it 'raises an error if no roles can be assigned' do
        deleted_role_id = SecureRandom.uuid
        # rubocop:disable Rails/SkipsModelValidations
        invitation.update_column(:role_ids, [deleted_role_id])
        # rubocop:enable Rails/SkipsModelValidations
        
        # Delete agent role to simulate missing fallback
        Access::Role.where(account_id: account.id, identifier: 'agent').destroy_all
        
        expect { service.call }.to raise_error(StandardError, I18n.t("accounts.invitations.errors.no_valid_roles"))
      end
    end

    context 'with an already accepted invitation' do
      before { invitation.update!(status: :accepted) }

      it 'raises an error' do
        expect { service.call }.to raise_error(StandardError, I18n.t("accounts.invitations.errors.already_accepted"))
      end
    end

    context 'with an expired invitation' do
      before { invitation.update!(expires_at: 1.day.ago) }

      it 'raises an error' do
        expect { service.call }.to raise_error(StandardError, I18n.t("accounts.invitations.errors.expired"))
      end
    end
  end
end

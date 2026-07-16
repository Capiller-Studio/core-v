require 'rails_helper'

RSpec.describe Accounts::Invitations::Update do
  let(:account) { create(:account) }
  let(:invitation) { create(:account_invitation, account: account, role_ids: [account.roles.find_by!(identifier: 'agent').id]) }
  let(:new_role_ids) { [account.roles.find_by!(identifier: 'administrator').id] }
  let(:service) { described_class.new(invitation: invitation, role_ids: new_role_ids) }

  describe '#call' do
    context 'when the invitation is pending' do
      it 'updates the role_ids' do
        service.call
        expect(invitation.reload.role_ids).to eq(new_role_ids)
      end
    end

    context 'when the invitation is not pending' do
      before { invitation.update!(status: :accepted) }

      it 'returns false and does not update' do
        result = service.call
        expect(result).to be false
        expect(invitation.reload.role_ids).not_to eq(new_role_ids)
      end
    end
  end
end

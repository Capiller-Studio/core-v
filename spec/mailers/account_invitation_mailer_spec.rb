# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountInvitationMailer, type: :mailer do
  describe '#invite' do
    let(:account) { create(:account, name: 'Acme Corp', locale: 'en') }
    let(:inviter) { create(:user, name: 'John Doe') }
    let(:role) do
      account.with_shard do
        create(:access_role, account: account, name: 'Support Agent')
      end
    end
    let(:invitation) do
      create(
        :account_invitation,
        account: account,
        invited_by: inviter,
        email: 'invitee@example.com',
        role_ids: [role.id]
      )
    end

    it 'renders the invitation email with correct headers and subject' do
      mail = described_class.with(invitation: invitation).invite

      expect(mail.to).to eq(['invitee@example.com'])
      expect(mail.subject).to include('Acme Corp')
    end
  end
end

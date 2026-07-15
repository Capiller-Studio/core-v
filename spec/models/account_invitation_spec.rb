require 'rails_helper'

RSpec.describe AccountInvitation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:invited_by) }
  end

  describe 'Validations' do
    let(:account) { create(:account) }
    let(:valid_role) { create(:access_role, account: account) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:role_ids) }

    it 'validates email format' do
      invitation = build(:account_invitation, email: 'invalid_email')
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include('is invalid')
    end

    it 'validates at least one role' do
      invitation = build(:account_invitation, role_ids: [])
      expect(invitation).not_to be_valid
      expect(invitation.errors[:role_ids]).to include('must contain at least one role')
    end

    it 'validates roles belong to the account' do
      other_account = create(:account)
      invalid_role = create(:access_role, account: other_account)
      
      invitation = build(:account_invitation, account: account, role_ids: [invalid_role.id])
      expect(invitation).not_to be_valid
      expect(invitation.errors[:role_ids]).to include('contains invalid roles for this account')
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, accepted: 1, expired: 2, revoked: 3) }
  end

  describe 'Callbacks' do
    it 'sets expiry date before validation on create' do
      invitation = build(:account_invitation, expires_at: nil)
      invitation.validate
      expect(invitation.expires_at).to be_present
      expect(invitation.expires_at).to be_within(1.minute).of(7.days.from_now)
    end
  end

  describe '#expired?' do
    it 'returns true if status is expired' do
      invitation = build(:account_invitation, status: :expired)
      expect(invitation.expired?).to be true
    end

    it 'returns true if pending and past expires_at' do
      invitation = build(:account_invitation, status: :pending, expires_at: 1.day.ago)
      expect(invitation.expired?).to be true
    end

    it 'returns false if pending and expires_at is in future' do
      invitation = build(:account_invitation, status: :pending, expires_at: 1.day.from_now)
      expect(invitation.expired?).to be false
    end
  end
end

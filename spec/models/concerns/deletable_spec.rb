# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deletable, type: :model do
  describe 'included behaviour on Account' do
    let(:account) { create(:account, name: 'Acme Corp', identifier: 'acme-org', referral_code: 'REF123') }

    it 'defines deletable_identifying_columns' do
      expect(Account.deletable_identifying_columns).to contain_exactly(:identifier, :referral_code)
      expect(account.deletable_identifying_columns).to contain_exactly(:identifier, :referral_code)
    end

    describe '#deactivate_for_deletion!' do
      it 'transitions status to pending_deletion and stores metadata' do
        expect(account).to receive(:after_deactivate_for_deletion).and_call_original

        account.deactivate_for_deletion!(reason: 'Customer requested', actor_id: 'user-1')

        expect(account.reload).to be_pending_deletion
        expect(account.data['deletion']['requested_at']).to be_present
        expect(account.data['deletion']['reason']).to eq('Customer requested')
        expect(account.data['deletion']['actor_id']).to eq('user-1')
      end

      it 'raises error when record is already deleted' do
        account.update_column(:status, Account.statuses[:deleted])
        expect { account.deactivate_for_deletion! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe '#mark_as_deleted!' do
      it 'archives identifying columns and record name, then nullifies columns in DB' do
        account.deactivate_for_deletion!
        expect(account).to receive(:after_mark_as_deleted).and_call_original

        account.mark_as_deleted!(reason: 'Staff approved', staff_id: 'staff-42')

        account.reload
        expect(account).to be_deleted
        expect(account.identifier).to be_nil
        expect(account.referral_code).to be_nil

        archived = account.data['archived_identity']
        expect(archived['identifier']).to eq('acme-org')
        expect(archived['referral_code']).to eq('REF123')
        expect(archived['name']).to eq('Acme Corp')
        expect(archived['deleted_at']).to be_present
        expect(archived['reason']).to eq('Staff approved')
        expect(archived['staff_id']).to eq('staff-42')
      end
    end

    describe '#restore_active!' do
      it 'restores vaulted columns and resets status to active' do
        account.deactivate_for_deletion!
        account.mark_as_deleted!

        expect(account).to receive(:before_restore_active).and_call_original
        expect(account).to receive(:after_restore_active).and_call_original

        account.restore_active!

        account.reload
        expect(account).to be_active
        expect(account.identifier).to eq('acme-org')
        expect(account.referral_code).to eq('REF123')
      end

      it 'raises RecordInvalid if an identifying column has been taken by another active record' do
        account.deactivate_for_deletion!
        account.mark_as_deleted!

        # Create another account with the original identifier
        create(:account, identifier: 'acme-org')

        expect { account.restore_active! }.to raise_error(ActiveRecord::RecordInvalid) do |err|
          expect(err.record.errors[:identifier]).to include('is already taken by another active record and cannot be restored')
        end
        expect(account.reload).to be_deleted
      end
    end
  end

  describe 'included behaviour on User' do
    let(:user) { create(:user, email: 'user@example.com', username: 'user123', confirmed_at: Time.current) }

    it 'defines deletable_identifying_columns' do
      expect(User.deletable_identifying_columns).to contain_exactly(:email, :username)
      expect(user.deletable_identifying_columns).to contain_exactly(:email, :username)
    end

    it 'vaults email and username upon mark_as_deleted!' do
      user.deactivate_for_deletion!
      user.mark_as_deleted!

      user.reload
      expect(user).to be_deleted
      expect(user.email).to be_nil
      expect(user.username).to be_nil
      expect(user.data['archived_identity']['email']).to eq('user@example.com')
      expect(user.data['archived_identity']['username']).to eq('user123')
    end

    it 'prevents restoration if email has since been registered by another user' do
      user.deactivate_for_deletion!
      user.mark_as_deleted!

      # Create new user with same email
      create(:user, email: 'user@example.com')

      expect { user.restore_active! }.to raise_error(ActiveRecord::RecordInvalid) do |err|
        expect(err.record.errors[:email]).to include('is already taken by another active record and cannot be restored')
      end
    end
  end
end

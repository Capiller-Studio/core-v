require 'rails_helper'

RSpec.describe Accounts::RegistrationService do
  describe '#call' do
    let(:country) { create(:country, iso: 'US') }
    let(:base_params) do
      {
        email: 'test@example.com',
        password: 'Password123!',
        first_name: 'John',
        last_name: 'Doe',
        country: country.iso
      }
    end

    context 'when creating an account with owner' do
      let(:params) { base_params.merge(account_name: 'Test Account', currency: 'USD', locale: 'en') }
      let(:service) { described_class.new(**params) }

      it 'creates a user, account, account user, address, and assigns roles' do
        result = nil
        expect {
          result = service.call
        }.to change(User, :count).by(1)
         .and change(Account, :count).by(1)
         .and change(AccountUser, :count).by(1)
         .and change(Access::AccountUserRole, :count).by(1)
         .and change(Address, :count).by(1)

        expect(result.success?).to be true
        expect(result.user.email).to eq('test@example.com')
        expect(result.user.address.country).to eq(country)
        expect(result.account.name).to eq('Test Account')
        
        account_user = AccountUser.last
        expect(account_user.user).to eq(result.user)
        expect(account_user.account).to eq(result.account)
        expect(account_user.owner).to be true

        role_assignment = Access::AccountUserRole.find_by(account_user_id: account_user.id)
        expect(role_assignment).to be_present
        expect(role_assignment.role.identifier).to eq('owner')
        expect(result.account.identifier).to eq('test-account')
      end

      it 'uses custom identifier when provided' do
        custom_service = described_class.new(**params.merge(identifier: 'custom-slug'))
        result = custom_service.call

        expect(result.success?).to be true
        expect(result.account.identifier).to eq('custom-slug')
      end
    end

    context 'when registering as an affiliate' do
      let(:params) { base_params.merge(as_affiliate: true, currency: 'EUR') }
      let(:service) { described_class.new(**params) }

      it 'creates an affiliate profile for the user' do
        result = nil
        expect {
          result = service.call
        }.to change(User, :count).by(1)
         .and change(Affiliate::Profile, :count).by(1)

        expect(result.success?).to be true
        expect(result.user.affiliate_profile.currency).to eq('EUR')
      end
      
      it 'defaults currency if none provided' do
        service = described_class.new(**base_params.merge(as_affiliate: true))
        result = service.call
        expect(result.user.affiliate_profile.currency).to eq('USD') # Default currency
      end
    end

    context 'when user validation fails' do
      let(:params) { base_params.merge(email: nil) }
      let(:service) { described_class.new(**params) }

      it 'returns a failure result with errors and rolls back' do
        expect {
          result = service.call
          expect(result.success?).to be false
          expect(result.user).to be_nil
          expect(result.errors).to include({ field: "email", message: "Email can't be blank" })
        }.to change(User, :count).by(0).and change(Address, :count).by(0)
      end
    end

    context 'when account validation fails' do
      let(:params) { base_params.merge(account_name: 'Test') }
      let(:service) { described_class.new(**params) }

      before do
        allow(Account).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Account.new.tap { |a| a.errors.add(:name, "can't be blank") }))
      end

      it 'rolls back the user creation and returns failure' do
        expect {
          result = service.call
          expect(result.success?).to be false
          expect(result.account).to be_nil
          expect(result.errors).to include({ field: "name", message: "Name can't be blank" })
        }.to change(Account, :count).by(0)
         .and change(User, :count).by(0)
         .and change(Address, :count).by(0)
      end
    end

    context 'when accepting an invitation' do
      let(:params) { base_params.merge(invitation_token: '12345') }
      let(:service) { described_class.new(**params) }

      it 'executes the pending invitation logic (currently returns nil account)' do
        result = service.call
        expect(result.success?).to be true
        expect(result.account).to be_nil
        expect(result.user.email).to eq('test@example.com')
      end
    end
  end
end

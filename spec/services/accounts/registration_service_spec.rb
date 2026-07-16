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

      it 'creates a user, account, and account user' do
        result = nil
        expect {
          result = service.call
        }.to change(User, :count).by(1)
         .and change(Account, :count).by(1)
         .and change(AccountUser, :count).by(1)
         .and change(Access::AccountUserRole, :count).by(1)

        expect(result.success?).to be true
        expect(result.user.email).to eq('test@example.com')
        expect(result.account.name).to eq('Test Account')
        
        account_user = AccountUser.last
        expect(account_user.user).to eq(result.user)
        expect(account_user.account).to eq(result.account)
        expect(account_user.owner).to be true
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
    end

    context 'when validation fails' do
      let(:params) { base_params.merge(email: nil) }
      let(:service) { described_class.new(**params) }

      it 'returns a failure result with errors' do
        result = service.call
        
        expect(result.success?).to be false
        expect(result.user).to be_nil
        expect(result.errors).to include({ field: "email", message: "Email can't be blank" })
      end
    end
  end
end

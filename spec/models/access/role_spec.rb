require 'rails_helper'

RSpec.describe Access::Role, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:account_user_roles) }
  end

  describe 'Validations' do
    subject { create(:access_role) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id) }
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let!(:system_role) { create(:access_role, account: account, system_provided: true) }
    let!(:custom_role) { create(:access_role, account: account, system_provided: false) }

    it 'filters system_roles' do
      expect(Access::Role.system_roles).to include(system_role)
      expect(Access::Role.system_roles).not_to include(custom_role)
    end

    it 'filters custom_roles' do
      expect(Access::Role.custom_roles).to include(custom_role)
      expect(Access::Role.custom_roles).not_to include(system_role)
    end
  end

  describe 'Callbacks' do
    it 'generates a slug/identifier on validation based on name' do
      role = build(:access_role, name: 'Support Agent', identifier: nil)
      role.validate
      expect(role.identifier).to be_present
      expect(role.identifier).to include('support-agent')
    end
  end
end

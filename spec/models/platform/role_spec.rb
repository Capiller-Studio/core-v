require 'rails_helper'

RSpec.describe Platform::Role, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:staff_roles) }
    it { is_expected.to have_many(:staffs) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:identifier) }
  end

  describe '#super_admin? and #admin?' do
    it 'identifies super_admin role correctly' do
      role = build(:platform_role, :super_admin)
      expect(role.super_admin?).to be true
      expect(role.admin?).to be true
    end

    it 'identifies admin role correctly' do
      role = build(:platform_role, :admin)
      expect(role.super_admin?).to be false
      expect(role.admin?).to be true
    end

    it 'identifies other roles correctly' do
      role = build(:platform_role, :support)
      expect(role.super_admin?).to be false
      expect(role.admin?).to be false
    end
  end

  describe 'Factory Traits' do
    it 'creates a super_admin role with all permissions from PERMISSION_SCHEMA' do
      role = create(:platform_role, :super_admin)
      expect(role.permissions.keys).to match_array(Platform::Role::PERMISSION_SCHEMA.keys)
    end

    it 'creates an admin role with permissions from PERMISSION_SCHEMA' do
      role = create(:platform_role, :admin)
      expect(role.permissions['accounts']).to eq(%w[read manage])
      expect(role.permissions['staff']).to eq(%w[read])
    end

    it 'creates a support role with standard permissions' do
      role = create(:platform_role, :support)
      expect(role.permissions['accounts']).to eq(%w[read manage])
      expect(role.permissions['channels']).to eq(%w[read manage])
    end
  end
end

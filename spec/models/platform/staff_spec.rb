require 'rails_helper'

RSpec.describe Platform::Staff, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:roles) }
    it { is_expected.to have_many(:staff_roles) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, suspended: 1, deactivated: 2) }
  end

  describe 'Role & Permission Helpers' do
    let(:staff) { create(:platform_staff, :active) }

    context 'when staff has super_admin role' do
      let(:super_admin_role) { create(:platform_role, :super_admin) }

      before { staff.roles << super_admin_role }

      it 'returns true for super_admin? and admin?' do
        expect(staff.super_admin?).to be true
        expect(staff.admin?).to be true
      end

      it 'returns false if staff is suspended or deactivated' do
        staff.status = :suspended
        expect(staff.super_admin?).to be false
        expect(staff.admin?).to be false

        staff.status = :deactivated
        expect(staff.super_admin?).to be false
        expect(staff.admin?).to be false
      end
    end

    context 'when staff has admin role' do
      let(:admin_role) { create(:platform_role, :admin) }

      before { staff.roles << admin_role }

      it 'returns true for admin? but false for super_admin?' do
        expect(staff.admin?).to be true
        expect(staff.super_admin?).to be false
      end

      it 'returns false for admin? when staff is suspended' do
        staff.status = :suspended
        expect(staff.admin?).to be false
      end
    end

    context 'when staff has support or regular role' do
      let(:support_role) { create(:platform_role, :support) }

      before { staff.roles << support_role }

      it 'returns false for both super_admin? and admin?' do
        expect(staff.super_admin?).to be false
        expect(staff.admin?).to be false
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Platform::PermissionService do
  let(:roles_scope) { double('RolesScope') }
  let(:staff) { double('Staff', active?: true, roles: roles_scope) }
  let(:service) { described_class.new(staff) }

  describe '.can?' do
    it 'delegates to instance method' do
      expect_any_instance_of(described_class).to receive(:can?).with('users', 'read')
      described_class.can?(staff, 'users', 'read')
    end
  end

  describe '#can?' do
    it 'returns false if staff is nil' do
      service = described_class.new(nil)
      expect(service.can?('users', 'read')).to be false
    end

    it 'returns false if staff is inactive' do
      allow(staff).to receive(:active?).and_return(false)
      expect(service.can?('users', 'read')).to be false
    end

    context 'when active staff' do
      before do
        allow(roles_scope).to receive(:exists?).with(identifier: "super_admin").and_return(false)
        allow(roles_scope).to receive(:each).and_yield(role)
      end

      let(:role) { double('Role', permissions: { "users" => { "read" => true, "write" => false } }) }

      it 'returns true if staff is super_admin' do
        allow(roles_scope).to receive(:exists?).with(identifier: "super_admin").and_return(true)
        expect(service.can?('users', 'write')).to be true
      end

      it 'returns true if permission is explicitly granted' do
        expect(service.can?('users', 'read')).to be true
      end

      it 'returns false if permission is explicitly denied' do
        expect(service.can?('users', 'write')).to be false
      end

      it 'returns false if resource is unknown' do
        expect(service.can?('unknown', 'read')).to be false
      end

      it 'merges permissions from multiple roles' do
        role2 = double('Role', permissions: { "users" => { "write" => true } })
        allow(roles_scope).to receive(:each).and_yield(role).and_yield(role2)
        
        expect(service.can?('users', 'read')).to be true
        expect(service.can?('users', 'write')).to be true
      end
    end
  end
end

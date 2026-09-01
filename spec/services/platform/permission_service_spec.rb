# frozen_string_literal: true

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
        allow(roles_scope).to receive(:exists?).with(identifier: 'super_admin').and_return(false)
        allow(roles_scope).to receive(:each).and_yield(role)
      end

      context 'with hash-based permissions' do
        let(:role) { double('Role', permissions: { 'users' => { 'read' => true, 'write' => false } }) }

        it 'returns true if staff is super_admin' do
          allow(roles_scope).to receive(:exists?).with(identifier: 'super_admin').and_return(true)
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
      end

      context 'with array-based permissions' do
        let(:role) { double('Role', permissions: { 'accounts' => ['read'], 'plans' => ['manage'] }) }

        it 'allows read on accounts' do
          expect(service.can?('accounts', 'read')).to be true
          expect(service.can?(:accounts, :read)).to be true
        end

        it 'denies manage on accounts' do
          expect(service.can?('accounts', 'manage')).to be false
        end

        it 'allows manage on plans' do
          expect(service.can?('plans', 'manage')).to be true
        end

        it 'allows read on plans because manage implies read' do
          expect(service.can?('plans', 'read')).to be true
        end
      end

      context 'with multiple roles' do
        let(:role) { double('Role', permissions: { 'accounts' => ['read'] }) }
        let(:role2) { double('Role', permissions: { 'accounts' => ['manage'], 'system_logs' => ['read'] }) }

        it 'merges permissions from all roles' do
          allow(roles_scope).to receive(:each).and_yield(role).and_yield(role2)

          expect(service.can?('accounts', 'manage')).to be true
          expect(service.can?('system_logs', 'read')).to be true
          expect(service.can?('users', 'read')).to be false
        end
      end
    end
  end
end

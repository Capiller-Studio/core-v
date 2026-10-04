# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessControl, type: :model do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let(:agent_user) { create(:user) }

  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }

  let(:owner_role) do
    account.with_shard do
      account.roles.find_by(identifier: 'owner') ||
        create(:access_role, account: account, identifier: 'owner', name: 'Owner', system_provided: true, permissions: { 'all' => { 'manage' => true } })
    end
  end

  let(:support_role) do
    account.with_shard do
      create(:access_role,
        account: account,
        identifier: 'support_agent',
        name: 'Support Agent',
        permissions: {
          'conversations' => { 'read' => true, 'write' => true },
          'contacts' => %w[read]
        }
      )
    end
  end

  let(:manager_role) do
    account.with_shard do
      create(:access_role,
        account: account,
        identifier: 'support_manager',
        name: 'Support Manager',
        permissions: {
          'automations' => { 'manage' => true },
          'teams' => { 'read' => true }
        }
      )
    end
  end

  describe '#can?' do
    context 'when the account user is an owner' do
      it 'bypasses all checks and returns true for any permission string' do
        expect(owner_account_user.can?('conversations.read')).to be true
        expect(owner_account_user.can?('automations.manage')).to be true
        expect(owner_account_user.can?('nonexistent.action')).to be true
      end

      it 'returns true even if owner has no roles assigned' do
        expect(owner_account_user.roles).to be_empty
        expect(owner_account_user.can?('anything.manage')).to be true
      end
    end

    context 'when the account user is not an owner' do
      context 'when having no roles assigned' do
        it 'returns false for any permission string' do
          expect(agent_account_user.can?('conversations.read')).to be false
          expect(agent_account_user.can?('teams.read')).to be false
        end
      end

      context 'when assigned a single role' do
        before do
          agent_account_user.assign_roles([support_role.id])
        end

        it 'returns true for permissions granted by the role' do
          expect(agent_account_user.can?('conversations.read')).to be true
          expect(agent_account_user.can?('conversations.write')).to be true
          expect(agent_account_user.can?('contacts.read')).to be true
        end

        it 'returns false for permissions not granted by the role' do
          expect(agent_account_user.can?('conversations.delete')).to be false
          expect(agent_account_user.can?('automations.manage')).to be false
          expect(agent_account_user.can?('teams.read')).to be false
        end
      end

      context 'when assigned multiple roles' do
        before do
          agent_account_user.assign_roles([support_role.id, manager_role.id])
        end

        it 'combines and merges permissions from all assigned roles' do
          expect(agent_account_user.can?('conversations.read')).to be true
          expect(agent_account_user.can?('automations.manage')).to be true
          expect(agent_account_user.can?('teams.read')).to be true
        end

        it 'returns false for permissions not in any role' do
          expect(agent_account_user.can?('roles.manage')).to be false
        end
      end

      context 'with resource-scoped conditional permissions' do
        let(:scoped_role) do
          account.with_shard do
            create(:access_role,
              account: account,
              identifier: 'inbox_restricted_agent',
              name: 'Inbox Restricted Agent',
              permissions: {
                'conversations' => {
                  'read' => { 'inbox_ids' => [101, 102] }
                }
              }
            )
          end
        end

        before do
          agent_account_user.assign_roles([scoped_role.id])
        end

        it 'returns true when general check without resource is performed' do
          expect(agent_account_user.can?('conversations.read')).to be true
        end

        it 'returns true when resource inbox matches allowed inbox_ids' do
          allowed_res = double('Conversation', id: 50, inbox_id: 101)
          expect(agent_account_user.can?('conversations.read', resource: allowed_res)).to be true
        end

        it 'returns false when resource inbox is outside allowed inbox_ids' do
          forbidden_res = double('Conversation', id: 51, inbox_id: 999)
          expect(agent_account_user.can?('conversations.read', resource: forbidden_res)).to be false
        end
      end
    end
  end

  describe '#assign_roles' do
    it 'creates shard role associations and resets associations' do
      expect {
        agent_account_user.assign_roles([support_role.id])
      }.to change {
        account.with_shard { Access::AccountUserRole.where(account_user_id: agent_account_user.id).count }
      }.by(1)

      expect(agent_account_user.roles).to include(support_role)
    end

    it 'removes existing roles when updated with new ones' do
      agent_account_user.assign_roles([support_role.id])
      expect(agent_account_user.roles).to eq([support_role])

      agent_account_user.assign_roles([manager_role.id])
      expect(agent_account_user.roles).to eq([manager_role])
    end

    it 'clears all roles when passed empty or blank list' do
      agent_account_user.assign_roles([support_role.id])
      expect(agent_account_user.roles).not_to be_empty

      agent_account_user.assign_roles([])
      expect(agent_account_user.roles).to be_empty
    end

    it 'silently ignores invalid or non-existent role IDs' do
      agent_account_user.assign_roles([support_role.id, 999_999_999, 'invalid-id'])
      expect(agent_account_user.roles).to eq([support_role])
    end

    context 'when called on owner' do
      before do
        owner_role # ensure created
      end

      it 'always preserves the owner role even if not included in role IDs' do
        owner_account_user.assign_roles([support_role.id])
        expect(owner_account_user.roles).to include(owner_role)
        expect(owner_account_user.roles).to include(support_role)

        owner_account_user.assign_roles([])
        expect(owner_account_user.roles).to include(owner_role)
      end
    end
  end
end

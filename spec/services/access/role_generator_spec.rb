require 'rails_helper'

RSpec.describe Access::RoleGenerator do
  let(:account) { double('Account') }
  let(:service) { described_class.new(account) }

  describe '#call' do
    let(:roles_scope) { double('RolesScope') }
    let(:owner_role) { double('Role') }
    let(:admin_role) { double('Role') }
    let(:agent_role) { double('Role') }

    before do
      allow(Access::Role).to receive(:transaction).and_yield
      allow(account).to receive(:with_shard).and_yield
      allow(account).to receive(:roles).and_return(roles_scope)
    end

    it 'creates owner, admin, and agent roles' do
      expect(roles_scope).to receive(:find_or_create_by!).with(identifier: "owner").and_yield(owner_role)
      expect(owner_role).to receive(:name=).with("Owner")
      expect(owner_role).to receive(:system_provided=).with(true)
      expect(owner_role).to receive(:permissions=).with(kind_of(Hash))

      expect(roles_scope).to receive(:find_or_create_by!).with(identifier: "administrator").and_yield(admin_role)
      expect(admin_role).to receive(:name=).with("Administrator")
      expect(admin_role).to receive(:system_provided=).with(true)
      expect(admin_role).to receive(:permissions=).with(hash_including("conversations" => { "read" => true, "write" => true, "delete" => true }))

      expect(roles_scope).to receive(:find_or_create_by!).with(identifier: "agent").and_yield(agent_role)
      expect(agent_role).to receive(:name=).with("Agent")
      expect(agent_role).to receive(:system_provided=).with(true)
      expect(agent_role).to receive(:permissions=).with(hash_including("conversations" => { "read" => true, "write" => true }))

      service.call
    end
  end
end

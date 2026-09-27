require 'rails_helper'

RSpec.describe Access::PermissionMerger do
  describe '#call' do
    let(:permissions_list) { [] }
    let(:resource_type) { "conversations" }
    let(:action) { "read" }
    let(:resource) { nil }
    
    let(:service) { described_class.new(permissions_list, resource_type, action, resource) }

    it 'returns false if permissions_list is empty' do
      expect(service.call).to be false
    end

    context 'with boolean permissions' do
      it 'returns true if any permission grants the action' do
        permissions_list << { "conversations" => { "read" => false } }
        permissions_list << { "conversations" => { "read" => true } }
        
        expect(service.call).to be true
      end

      it 'returns true if any permission grants manage' do
        permissions_list << { "conversations" => { "manage" => true } }
        
        expect(service.call).to be true
      end

      it 'returns false if manage is true but action is manage (prevents infinite loop/redundancy)' do
        # If action is 'manage', it checks the 'manage' key.
        service = described_class.new([{"conversations" => {"manage" => true}}], "conversations", "manage")
        expect(service.call).to be true
      end

      it 'returns false if action is not granted and manage is not granted' do
        permissions_list << { "conversations" => { "read" => false, "manage" => false } }
        expect(service.call).to be false
      end
    end

    context 'with conditional permissions (Hash)' do
      let(:resource) { double('Conversation', id: 10, inbox_id: 5) }

      it 'returns true if resource matches inbox_ids' do
        permissions_list << { "conversations" => { "read" => { "inbox_ids" => [5, 6] } } }
        expect(service.call).to be true
      end

      it 'returns false if resource does not match inbox_ids' do
        permissions_list << { "conversations" => { "read" => { "inbox_ids" => [7, 8] } } }
        expect(service.call).to be false
      end

      it 'returns true if resource matches ids' do
        permissions_list << { "conversations" => { "read" => { "ids" => [10] } } }
        expect(service.call).to be true
      end

      it 'returns false if condition key is unknown' do
        permissions_list << { "conversations" => { "read" => { "unknown_key" => [1] } } }
        expect(service.call).to be false
      end

      it 'returns true if resource is nil for a hash policy (general capability check)' do
        service = described_class.new([{"conversations" => {"read" => {"inbox_ids" => [5]}}}], "conversations", "read", nil)
        expect(service.call).to be true
      end
    end

    context 'with array permissions' do
      it 'returns true if action is in permissions array' do
        permissions_list << { "conversations" => %w[read write] }
        expect(service.call).to be true
      end

      it 'returns true if manage is in permissions array' do
        permissions_list << { "conversations" => %w[manage] }
        expect(service.call).to be true
      end

      it 'returns false if neither action nor manage is in array' do
        permissions_list << { "conversations" => %w[delete] }
        expect(service.call).to be false
      end
    end
  end
end

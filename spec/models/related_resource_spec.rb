# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RelatedResource, type: :model do
  let(:account) { create(:account) }
  let(:conv1) { create(:conversation, account: account) }
  let(:conv2) { create(:conversation, account: account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:linked_resource) }
  end

  describe 'creation' do
    it 'creates a polymorphic link between two resources' do
      rel = account.with_shard do
        described_class.create!(resource: conv1, linked_resource: conv2)
      end

      expect(rel).to be_persisted
      expect(rel.resource).to eq(conv1)
      expect(rel.linked_resource).to eq(conv2)
    end
  end
end

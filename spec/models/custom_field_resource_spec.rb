# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomFieldResource, type: :model do
  let(:account) { create(:account) }
  let(:custom_field) do
    account.with_shard do
      create(:custom_field, account: account, label: 'Order Number', field_type: :text)
    end
  end
  let(:contact_form) do
    account.with_shard do
      create(:channel_contact_form, account: account)
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:custom_field) }
    it { is_expected.to belong_to(:resource) }
  end

  describe 'creation and configuration overrides' do
    it 'creates a custom field resource binding with position and overrides' do
      cfr = account.with_shard do
        described_class.create!(
          custom_field: custom_field,
          resource: contact_form,
          position: 2,
          required_override: true,
          configurations: { 'width' => 'half', 'read_only' => false }
        )
      end

      expect(cfr).to be_persisted
      expect(cfr.position).to eq(2)
      expect(cfr.required_override).to be(true)
      expect(cfr.configurations['width']).to eq('half')
    end
  end
end

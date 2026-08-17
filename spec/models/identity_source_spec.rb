# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IdentitySource, type: :model do
  let(:account) { create(:account) }

  describe 'Associations and Enums' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to define_enum_for(:source_type).with_values(api: 0) }
  end

  describe 'defaults and URL safety validations' do
    it 'initializes default hashes before validation' do
      source = account.with_shard do
        described_class.create!(
          account: account,
          name: 'Clearbit Lookup',
          source_url: 'https://api.clearbit.com/v2/people/find'
        )
      end

      expect(source.headers).to eq({})
      expect(source.params).to eq({})
      expect(source.response_mapping).to eq({})
      expect(source.configurations).to eq({})
    end
  end
end

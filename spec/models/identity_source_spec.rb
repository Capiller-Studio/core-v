# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IdentitySource, type: :model do
  let(:account) { create(:account) }

  describe 'Associations and Enums' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to define_enum_for(:source_type).with_values(api: 0) }
  end

  describe 'defaults and URL safety validations' do
    before do
      allow(Resolv).to receive(:getaddresses).and_call_original
      allow(Resolv).to receive(:getaddresses).with('api.example.com').and_return(['93.184.216.34'])
    end

    it 'initializes default hashes before validation' do
      source = account.with_shard do
        described_class.create!(
          account: account,
          name: 'Customer Lookup',
          source_url: 'https://api.example.com/people/find'
        )
      end

      expect(source.headers).to eq({})
      expect(source.params).to eq({})
      expect(source.response_mapping).to eq({})
      expect(source.configurations).to eq({})
    end

    it 'allows valid external HTTPS URLs' do
      source = build(:identity_source, account: account, source_url: 'https://api.example.com/lookup')
      expect(source).to be_valid
    end

    it 'rejects localhost and 127.0.0.1' do
      source = build(:identity_source, account: account, source_url: 'http://localhost:8080/data')
      expect(source).not_to be_valid
      expect(source.errors[:source_url]).to include('cannot point to localhost or internal network spaces')

      source2 = build(:identity_source, account: account, source_url: 'http://127.0.0.1:3000/data')
      expect(source2).not_to be_valid
      expect(source2.errors[:source_url]).to include('cannot point to localhost or internal network spaces')
    end

    it 'rejects AWS/cloud metadata address' do
      source = build(:identity_source, account: account, source_url: 'http://169.254.169.254/latest/meta-data')
      expect(source).not_to be_valid
      expect(source.errors[:source_url]).to include('cannot point to internal or private IP addresses')
    end

    it 'rejects private RFC1918 subnets' do
      source = build(:identity_source, account: account, source_url: 'http://192.168.1.50/users')
      expect(source).not_to be_valid
      expect(source.errors[:source_url]).to include('cannot point to internal or private IP addresses')

      source2 = build(:identity_source, account: account, source_url: 'http://10.0.0.1/users')
      expect(source2).not_to be_valid
      expect(source2.errors[:source_url]).to include('cannot point to internal or private IP addresses')
    end

    it 'rejects internal domains' do
      source = build(:identity_source, account: account, source_url: 'http://backend.internal/api')
      expect(source).not_to be_valid
      expect(source.errors[:source_url]).to include('cannot point to localhost or internal network spaces')
    end

    it 'rejects invalid URL formats' do
      source = build(:identity_source, account: account, source_url: 'not-a-url')
      expect(source).not_to be_valid
      expect(source.errors[:source_url]).to include('must be a valid URL format')
    end
  end
end

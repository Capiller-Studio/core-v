require 'rails_helper'

RSpec.describe Domain, type: :model do
  subject(:domain) { build(:domain) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_one(:portal).class_name('HelpCenter::Portal').dependent(:nullify) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1, suspended: 2) }
    it { is_expected.to define_enum_for(:domain_type).with_values(subdomain: 0, custom: 1) }
    it { is_expected.to define_enum_for(:dns_status).with_values(dns_unverified: 0, dns_pending: 1, dns_verified: 2, dns_failed: 3) }
    it { is_expected.to define_enum_for(:ssl_status).with_values(ssl_none: 0, ssl_pending: 1, ssl_active: 2, ssl_expired: 3, ssl_failed: 4) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:domain_type) }

    it 'validates uniqueness of value (case-insensitive)' do
      create(:domain, value: 'uniquetest')
      is_expected.to validate_uniqueness_of(:value).case_insensitive
    end
  end

  describe 'Subdomain Defaults' do
    let(:subdomain) { create(:domain, :subdomain, value: 'mycompany') }

    it 'appends .helpbolic.com suffix' do
      expect(subdomain.value).to eq('mycompany.helpbolic.com')
    end

    it 'does not double-append suffix' do
      domain = create(:domain, :subdomain, value: 'mycompany2.helpbolic.com')
      expect(domain.value).to eq('mycompany2.helpbolic.com')
    end

    it 'auto-sets dns_status to dns_verified' do
      expect(subdomain).to be_dns_verified
    end

    it 'auto-sets ssl_status to ssl_active' do
      expect(subdomain).to be_ssl_active
    end

    it 'sets cname_target to empty string' do
      expect(subdomain.cname_target).to eq('')
    end

    it 'normalizes value to lowercase' do
      domain = create(:domain, :subdomain, value: 'MyCompany3')
      expect(domain.value).to eq('mycompany3.helpbolic.com')
    end

    it 'strips whitespace from value' do
      domain = create(:domain, :subdomain, value: '  mycompany4  ')
      expect(domain.value).to eq('mycompany4.helpbolic.com')
    end
  end

  describe 'Subdomain Format Validation' do
    it 'rejects slugs shorter than 3 characters' do
      domain = build(:domain, :subdomain, value: 'ab')
      expect(domain).not_to be_valid
      expect(domain.errors[:value].join).to include('at least 3')
    end

    it 'rejects slugs longer than 63 characters' do
      domain = build(:domain, :subdomain, value: 'a' * 64)
      expect(domain).not_to be_valid
      expect(domain.errors[:value].join).to include('at most 63')
    end

    it 'rejects slugs starting with a hyphen' do
      domain = build(:domain, :subdomain, value: '-invalid')
      expect(domain).not_to be_valid
    end

    it 'rejects slugs ending with a hyphen' do
      domain = build(:domain, :subdomain, value: 'invalid-')
      expect(domain).not_to be_valid
    end

    it 'allows hyphens in the middle' do
      domain = create(:domain, :subdomain, value: 'my-company5')
      expect(domain).to be_valid
      expect(domain.value).to eq('my-company5.helpbolic.com')
    end

    it 'rejects special characters' do
      domain = build(:domain, :subdomain, value: 'invalid_name!')
      expect(domain).not_to be_valid
    end
  end

  describe 'Reserved Subdomain Validation' do
    %w[www mail admin api support help billing dashboard login].each do |reserved|
      it "rejects reserved name '#{reserved}'" do
        domain = build(:domain, :subdomain, value: reserved)
        expect(domain).not_to be_valid
        expect(domain.errors[:value].join).to include('reserved')
      end
    end

    %w[deskbolic helpbolic techbolic].each do |brand|
      it "rejects brand name '#{brand}'" do
        domain = build(:domain, :subdomain, value: brand)
        expect(domain).not_to be_valid
      end
    end

    %w[fraud phishing spam scam hack].each do |abuse|
      it "rejects abuse term '#{abuse}'" do
        domain = build(:domain, :subdomain, value: abuse)
        expect(domain).not_to be_valid
      end
    end

    it 'allows non-reserved names' do
      domain = create(:domain, :subdomain, value: 'acme-corp')
      expect(domain).to be_valid
    end
  end

  describe 'Custom Domain Defaults' do
    let(:custom) { create(:domain, :custom, value: 'support.example.com') }

    it 'does not append subdomain suffix' do
      expect(custom.value).to eq('support.example.com')
    end

    it 'sets dns_status to dns_unverified for new records' do
      expect(custom).to be_dns_unverified
    end

    it 'sets ssl_status to ssl_none for new records' do
      expect(custom).to be_ssl_none
    end

    it 'sets cname_target to the canonical target' do
      expect(custom.cname_target).to eq(Domain::CNAME_TARGET)
    end
  end

  describe 'Custom Domain Format Validation' do
    %w[just-a-word missing-tld. .starts-with-dot.com].each do |bad|
      it "rejects invalid format '#{bad}'" do
        domain = build(:domain, :custom, value: bad)
        expect(domain).not_to be_valid
      end
    end

    it 'accepts valid custom domain formats' do
      domain = build(:domain, :custom, value: 'support.mycompany.com')
      # Reset dns/ssl to match expected custom defaults
      domain.dns_status = :dns_unverified
      domain.ssl_status = :ssl_none
      expect(domain).to be_valid
    end

    it 'rejects helpbolic.com subdomains as custom domains' do
      domain = build(:domain, :custom, value: 'sneaky.helpbolic.com')
      expect(domain).not_to be_valid
      expect(domain.errors[:value].join).to include('helpbolic.com')
    end
  end

  describe 'Scopes' do
    let!(:account) { create(:account) }
    let!(:sub) { create(:domain, :subdomain, value: 'scopetest1', account: account) }
    let!(:custom) { create(:domain, :custom, value: 'scope1.example.com', account: account) }

    describe '.subdomains' do
      it 'returns only subdomain types' do
        expect(Domain.subdomains).to include(sub)
        expect(Domain.subdomains).not_to include(custom)
      end
    end

    describe '.custom_domains' do
      it 'returns only custom types' do
        expect(Domain.custom_domains).to include(custom)
        expect(Domain.custom_domains).not_to include(sub)
      end
    end

    describe '.needing_dns_check' do
      it 'returns unverified and pending custom domains' do
        pending_domain = create(:domain, :custom, :dns_pending, value: 'pending.example.com', account: account)
        expect(Domain.needing_dns_check).to include(custom, pending_domain)
        expect(Domain.needing_dns_check).not_to include(sub)
      end
    end
  end

  describe 'Instance Methods' do
    describe '#subdomain_slug' do
      it 'returns slug without suffix for subdomains' do
        domain = create(:domain, :subdomain, value: 'myslug')
        expect(domain.subdomain_slug).to eq('myslug')
      end

      it 'returns nil for custom domains' do
        domain = create(:domain, :custom, value: 'slug.example.com')
        expect(domain.subdomain_slug).to be_nil
      end
    end

    describe '#operational?' do
      it 'returns true for active subdomains' do
        domain = create(:domain, :subdomain, value: 'operational1')
        expect(domain).to be_operational
      end

      it 'returns true for custom domains with verified DNS and active SSL' do
        domain = create(:domain, :custom, :dns_verified, :ssl_active, value: 'operational.example.com')
        expect(domain).to be_operational
      end

      it 'returns false for custom domains without DNS verification' do
        domain = create(:domain, :custom, value: 'notoperational.example.com')
        expect(domain).not_to be_operational
      end
    end

    describe '#dns_instructions' do
      it 'returns nil for subdomains' do
        domain = create(:domain, :subdomain, value: 'nodns')
        expect(domain.dns_instructions).to be_nil
      end

      it 'returns instruction hash for custom domains' do
        domain = create(:domain, :custom, value: 'instructions.example.com')
        instructions = domain.dns_instructions

        expect(instructions[:record_type]).to eq(I18n.t('domains.dns_instructions.record_type'))
        expect(instructions[:host]).to eq('instructions.example.com')
        expect(instructions[:target]).to eq(Domain::CNAME_TARGET)
        expect(instructions[:description]).to include('instructions.example.com')
      end
    end
  end

  describe 'Constants' do
    it 'defines SUBDOMAIN_SUFFIX as .helpbolic.com' do
      expect(Domain::SUBDOMAIN_SUFFIX).to eq('.helpbolic.com')
    end

    it 'defines CNAME_TARGET as custom.helpbolic.com' do
      expect(Domain::CNAME_TARGET).to eq('custom.helpbolic.com')
    end

    it 'freezes RESERVED_SUBDOMAINS' do
      expect(Domain::RESERVED_SUBDOMAINS).to be_frozen
    end

    it 'includes common infrastructure names in reserved list' do
      %w[www mail api admin support help dashboard].each do |name|
        expect(Domain::RESERVED_SUBDOMAINS).to include(name)
      end
    end
  end
end

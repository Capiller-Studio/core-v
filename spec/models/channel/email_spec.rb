require 'rails_helper'

RSpec.describe Channel::Email, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_one(:primary_inbox) }
  end

  describe 'Flags' do
    it { is_expected.to respond_to(:imap_enabled) }
    it { is_expected.to respond_to(:smtp_enabled) }
  end

  describe 'Validations' do
    subject { create(:channel_email) }
    
    it 'validates uniqueness of email scoped to account_id' do
      duplicate = build(:channel_email, account: subject.account, email: subject.email)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end
    
    it 'validates uniqueness of forward_email' do
      duplicate = build(:channel_email, forward_email: subject.forward_email)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:forward_email]).to include("has already been taken")
    end
    
    context 'when imap_enabled' do
      it 'validates imap_configurations' do
        ce = build(:channel_email, imap_enabled: true, imap_configurations: {})
        ce.valid?
        expect(ce.errors[:base]).to include("IMAP Address is required when IMAP is enabled")
      end
    end

    context 'when smtp_enabled' do
      it 'validates smtp_configurations' do
        ce = build(:channel_email, smtp_enabled: true, smtp_configurations: {})
        ce.valid?
        expect(ce.errors[:base]).to include("SMTP Address is required when SMTP is enabled")
      end
    end
  end

  describe 'Callbacks' do
    it 'generates forward_email on create' do
      ce = build(:channel_email, forward_email: nil)
      ce.save
      expect(ce.forward_email).to be_present
    end
  end

  describe 'Instance Methods' do
    it '#forward_email_domain returns the domain part of the forward email' do
      ce = build(:channel_email, forward_email: 'test@forward.example.com')
      expect(ce.forward_email_domain).to eq('forward.example.com')
    end

    it '#supported_formatting returns an array' do
      ce = build(:channel_email)
      expect(ce.supported_formatting).to include(:bold, :italic, :strikethrough)
    end

    describe '#smtp_delivery_options' do
      it 'falls back to email domain when smtp domain is blank or missing' do
        ce = build(:channel_email,
                   email: 'support@myhelpdesk.com',
                   smtp_enabled: true,
                   smtp_configurations: {
                     'address' => 'smtp.provider.com',
                     'port' => 587,
                     'username' => 'apikey',
                     'password' => 'secret',
                     'domain' => '',
                     'authentication' => 'plain'
                   })
        opts = ce.smtp_delivery_options
        expect(opts[:domain]).to eq('myhelpdesk.com')
      end

      it 'uses explicit smtp domain when provided' do
        ce = build(:channel_email,
                   email: 'support@myhelpdesk.com',
                   smtp_enabled: true,
                   smtp_configurations: {
                     'address' => 'smtp.provider.com',
                     'domain' => 'custom-smtp.com'
                   })
        opts = ce.smtp_delivery_options
        expect(opts[:domain]).to eq('custom-smtp.com')
      end

      it 'falls back to username domain if channel email has no domain' do
        ce = build(:channel_email,
                   email: nil,
                   smtp_enabled: true,
                   smtp_configurations: {
                     'address' => 'smtp.provider.com',
                     'username' => 'admin@mailprovider.org'
                   })
        opts = ce.smtp_delivery_options
        expect(opts[:domain]).to eq('mailprovider.org')
      end

      it 'omits domain key if no domain can be derived' do
        ce = build(:channel_email,
                   email: nil,
                   smtp_enabled: true,
                   smtp_configurations: {
                     'address' => 'smtp.provider.com',
                     'username' => 'apikey_without_domain'
                   })
        opts = ce.smtp_delivery_options
        expect(opts).not_to have_key(:domain)
      end
    end
  end
end

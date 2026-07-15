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
  end
end

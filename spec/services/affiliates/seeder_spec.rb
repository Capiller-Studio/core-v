require 'rails_helper'

RSpec.describe Affiliates::Seeder do
  let(:service) { described_class.new }

  describe '#call' do
    it 'seeds affiliate data without errors' do
      # Avoid logging output during test
      allow($stdout).to receive(:puts)
      
      expect { service.call }.not_to raise_error

      user = User.find_by(email: "affiliate@example.com")
      expect(user).to be_present
      expect(user.affiliate_profile).to be_present
      
      expect(user.affiliate_profile.referrals.count).to eq(10)
    end
  end
end

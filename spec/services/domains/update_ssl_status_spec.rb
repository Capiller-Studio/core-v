require 'rails_helper'

RSpec.describe Domains::UpdateSslStatus do
  let(:domain) { double('Domain', ssl_added_at: nil) }
  let(:service) { described_class.new(domain: domain, status: 'ssl_active', expires_at: '2027-01-01') }

  describe '#call' do
    it 'updates ssl status and sets ssl_added_at when active' do
      expect(domain).to receive(:update!).with(
        hash_including(
          ssl_status: 'ssl_active',
          ssl_expires_at: '2027-01-01'
        )
      ) do |args|
        expect(args[:last_checked_at]).to be_present
        expect(args[:ssl_added_at]).to be_present
      end
      
      service.call
    end

    it 'does not override ssl_added_at if already set' do
      allow(domain).to receive(:ssl_added_at).and_return(1.day.ago)
      
      expect(domain).to receive(:update!).with(
        hash_including(
          ssl_status: 'ssl_active',
          ssl_expires_at: '2027-01-01'
        )
      ) do |args|
        expect(args).not_to have_key(:ssl_added_at)
      end
      
      service.call
    end

    it 'updates status without expires_at' do
      service = described_class.new(domain: domain, status: 'ssl_failed')
      
      expect(domain).to receive(:update!).with(
        hash_including(ssl_status: 'ssl_failed')
      ) do |args|
        expect(args).not_to have_key(:ssl_added_at)
        expect(args).not_to have_key(:ssl_expires_at)
      end
      
      service.call
    end
  end
end

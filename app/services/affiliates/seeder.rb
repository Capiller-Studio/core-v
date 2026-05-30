# frozen_string_literal: true

module Affiliates
  class Seeder < ApplicationService
    def call
      puts "Seeding Affiliate Data..."
      
      # 1. Ensure user exists
      user = User.find_by(email: "affiliate@example.com")
      unless user
        country = Country.find_or_create_by!(iso: "US", iso3: "USA", iso_name: "UNITED STATES")
        address = Address.create!(country: country, address1: "123 Main St", city: "New York", zipcode: "10001")
        user = User.create!(
          email: "affiliate@example.com",
          password: "password123",
          first_name: "John",
          last_name: "Affiliate",
          address: address,
          dob: "1990-01-01",
          confirmed_at: Time.current
        )
      end

      # 2. Ensure affiliate profile exists
      profile = user.affiliate_profile || user.create_affiliate_profile!(
        currency: "USD",
        payment_method_type: :bank,
        payment_details: {
          "account_holder_name" => "John Affiliate",
          "legal_type" => "PRIVATE",
          "routing_number" => "121000358",
          "account_number" => "123456789",
          "account_type" => "CHECKING"
        },
        payouts_enabled: true
      )

      # 3. Create dummy referred users and referrals
      10.times do |i|
        referred = User.find_or_create_by!(email: "referred_#{i}@example.com") do |u|
          u.password = "password123"
          u.first_name = "Referred"
          u.last_name = i.to_s
          u.confirmed_at = Time.current
        end

        referral = profile.referrals.find_or_create_by!(referred_user: referred) do |r|
          r.status = i.even? ? :converted : :pending
          r.created_at = rand(1..30).days.ago
        end
        
        # Create some commissions for converted referrals
        if referral.converted?
          profile.commissions.find_or_create_by!(referral: referral) do |c|
            c.amount = rand(50.0..250.0).round(2)
            c.status = [:pending, :available, :paid].sample
            c.created_at = referral.created_at + 1.day
          end
        end
      end

      # 4. Create historical payouts for dashboard metrics
      paid_commissions = profile.commissions.where(status: :paid)
      if paid_commissions.any? && profile.payouts.empty?
        profile.payouts.create!(
          amount: paid_commissions.sum(:amount),
          currency: profile.currency,
          status: :paid,
          commission_ids: paid_commissions.pluck(:id)
        )
      end

      puts "Affiliate Seeding Complete for user: #{user.email}"
    end
  end
end

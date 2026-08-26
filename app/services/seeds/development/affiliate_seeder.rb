# frozen_string_literal: true

module Seeds
  module Development
    class AffiliateSeeder
      def self.seed(...)
        new(...).seed
      end

      def seed
        puts "\n🌱 Seeding affiliate system development data...\n"

        ensure_countries!

        ActiveRecord::Base.transaction do
          clean_previous_test_runs!

          affiliate1 = seed_affiliate_sophia!
          affiliate2 = seed_affiliate_marcus!
          affiliate3 = seed_affiliate_elena!
          affiliate4 = seed_affiliate_david!
          affiliate5 = seed_affiliate_oliver!

          seed_historical_payout_batch!(affiliate1, affiliate2)

          puts "✅ Affiliate development seeder completed successfully!"
          puts "   - Seeded 5 affiliate profiles (USD, EUR, GBP)"
          puts "   - Seeded customer referrals & transactions"
          puts "   - Seeded available, pending, paid commissions"
          puts "   - Seeded historical completed payout batch and payouts"
        end
      end

      private

      def ensure_countries!
        @country_us = Country.find_or_create_by!(iso: "US") do |c|
          c.iso3 = "USA"
          c.iso_name = "United States"
          c.numeric_code = 840
        end

        @country_gb = Country.find_or_create_by!(iso: "GB") do |c|
          c.iso3 = "GBR"
          c.iso_name = "United Kingdom"
          c.numeric_code = 826
        end

        @country_de = Country.find_or_create_by!(iso: "DE") do |c|
          c.iso3 = "DEU"
          c.iso_name = "Germany"
          c.numeric_code = 276
        end
      end

      def seed_affiliate_sophia!
        user = find_or_create_user(
          email: "sophia.turner@deskbolic.test",
          first_name: "Sophia",
          last_name: "Turner",
          country: @country_us,
          city: "San Francisco",
          address1: "100 Market St",
          zipcode: "94105"
        )

        profile = Affiliate::Profile.find_or_initialize_by(user: user)
        profile.referral_code = "sophia-turner"
        profile.commission_rate = 30.0
        profile.holding_days = 30
        profile.tenure_months = 12
        profile.currency = "USD"
        profile.payouts_enabled = true
        profile.payment_method_type = :bank
        profile.payment_details = {
          "account_holder_name" => "Sophia Turner",
          "routing_number" => "111000025",
          "account_number" => "9876543210",
          "account_type" => "checking",
          "bank_name" => "Chase Bank"
        }
        profile.save!

        # Referrals & Commissions
        acme_account = find_or_create_account(
          name: "Acme Corporation",
          identifier: "acme-corp",
          owner_email: "owner@acme-corp.test",
          owner_first_name: "Alice",
          owner_last_name: "Smith"
        )
        referral_acme = Affiliate::Referral.find_or_create_by!(profile: profile, account: acme_account) do |r|
          r.status = :active
          r.created_at = 2.months.ago
        end

        nexa_account = find_or_create_account(
          name: "Nexa Labs",
          identifier: "nexa-labs",
          owner_email: "owner@nexa-labs.test",
          owner_first_name: "Bob",
          owner_last_name: "Jones"
        )
        referral_nexa = Affiliate::Referral.find_or_create_by!(profile: profile, account: nexa_account) do |r|
          r.status = :active
          r.created_at = 1.month.ago
        end

        # Commissions for Acme (paid, available, available)
        seed_commission(profile: profile, referral: referral_acme, amount: 29.70, status: :paid, created_at: 45.days.ago)
        seed_commission(profile: profile, referral: referral_acme, amount: 35.00, status: :available, created_at: 15.days.ago)
        seed_commission(profile: profile, referral: referral_acme, amount: 42.50, status: :available, created_at: 5.days.ago)

        # Commissions for Nexa (available, pending)
        seed_commission(profile: profile, referral: referral_nexa, amount: 14.70, status: :available, created_at: 10.days.ago)
        seed_commission(profile: profile, referral: referral_nexa, amount: 18.50, status: :pending, created_at: 2.days.ago)

        profile
      end

      def seed_affiliate_marcus!
        user = find_or_create_user(
          email: "marcus.vance@deskbolic.test",
          first_name: "Marcus",
          last_name: "Vance",
          country: @country_us,
          city: "New York",
          address1: "550 Broadway",
          zipcode: "10012"
        )

        profile = Affiliate::Profile.find_or_initialize_by(user: user)
        profile.referral_code = "marcus-agency"
        profile.commission_rate = 25.0
        profile.holding_days = 14
        profile.tenure_months = 24
        profile.currency = "USD"
        profile.payouts_enabled = true
        profile.payment_method_type = :bank
        profile.payment_details = {
          "account_holder_name" => "Marcus Vance",
          "routing_number" => "021000021",
          "account_number" => "4567891234",
          "account_type" => "checking",
          "bank_name" => "Bank of America"
        }
        profile.save!

        velocity_account = find_or_create_account(
          name: "Velocity Media",
          identifier: "velocity-media",
          owner_email: "contact@velocity-media.test",
          owner_first_name: "Victor",
          owner_last_name: "Lane"
        )
        referral_velocity = Affiliate::Referral.find_or_create_by!(profile: profile, account: velocity_account) do |r|
          r.status = :active
          r.created_at = 2.months.ago
        end

        horizon_account = find_or_create_account(
          name: "Horizon Digital",
          identifier: "horizon-digital",
          owner_email: "hello@horizon-digital.test",
          owner_first_name: "Hannah",
          owner_last_name: "Ray"
        )
        referral_horizon = Affiliate::Referral.find_or_create_by!(profile: profile, account: horizon_account) do |r|
          r.status = :active
          r.created_at = 3.weeks.ago
        end

        seed_commission(profile: profile, referral: referral_velocity, amount: 74.75, status: :paid, created_at: 40.days.ago)
        seed_commission(profile: profile, referral: referral_velocity, amount: 74.75, status: :available, created_at: 10.days.ago)
        seed_commission(profile: profile, referral: referral_horizon, amount: 24.75, status: :available, created_at: 7.days.ago)

        profile
      end

      def seed_affiliate_elena!
        user = find_or_create_user(
          email: "elena.rostova@deskbolic.test",
          first_name: "Elena",
          last_name: "Rostova",
          country: @country_de,
          city: "Berlin",
          address1: "Friedrichstraße 43",
          zipcode: "10117"
        )

        profile = Affiliate::Profile.find_or_initialize_by(user: user)
        profile.referral_code = "elena-growth"
        profile.commission_rate = 20.0
        profile.holding_days = 30
        profile.tenure_months = 12
        profile.currency = "EUR"
        profile.payouts_enabled = true
        profile.payment_method_type = :bank
        profile.payment_details = {
          "account_holder_name" => "Elena Rostova",
          "iban" => "DE89370400440532013000",
          "bank_name" => "Deutsche Bank"
        }
        profile.save!

        klangwerk_account = find_or_create_account(
          name: "Klangwerk Audio",
          identifier: "klangwerk-audio",
          currency: "EUR",
          owner_email: "info@klangwerk.test",
          owner_first_name: "Klaus",
          owner_last_name: "Becker"
        )
        referral_klangwerk = Affiliate::Referral.find_or_create_by!(profile: profile, account: klangwerk_account) do |r|
          r.status = :active
          r.created_at = 1.month.ago
        end

        seed_commission(profile: profile, referral: referral_klangwerk, amount: 29.80, currency: "EUR", status: :available, created_at: 12.days.ago)
        seed_commission(profile: profile, referral: referral_klangwerk, amount: 29.80, currency: "EUR", status: :pending, created_at: 2.days.ago)

        profile
      end

      def seed_affiliate_david!
        user = find_or_create_user(
          email: "david.kim@deskbolic.test",
          first_name: "David",
          last_name: "Kim",
          country: @country_us,
          city: "Seattle",
          address1: "400 Pine St",
          zipcode: "98101"
        )

        profile = Affiliate::Profile.find_or_initialize_by(user: user)
        profile.referral_code = "david-consult"
        profile.commission_rate = 25.0
        profile.holding_days = 30
        profile.tenure_months = 12
        profile.currency = "USD"
        profile.payouts_enabled = false
        profile.payment_method_type = :bank
        profile.payment_details = {
          "account_holder_name" => "David Kim",
          "routing_number" => "125000024",
          "account_number" => "3216549870",
          "account_type" => "checking",
          "bank_name" => "Wells Fargo"
        }
        profile.save!

        pulse_account = find_or_create_account(
          name: "Pulse Analytics",
          identifier: "pulse-analytics",
          owner_email: "support@pulse-analytics.test",
          owner_first_name: "Paul",
          owner_last_name: "Davies"
        )
        referral_pulse = Affiliate::Referral.find_or_create_by!(profile: profile, account: pulse_account) do |r|
          r.status = :active
          r.created_at = 3.weeks.ago
        end

        seed_commission(profile: profile, referral: referral_pulse, amount: 49.75, status: :available, created_at: 8.days.ago)

        profile
      end

      def seed_affiliate_oliver!
        user = find_or_create_user(
          email: "oliver.smith@deskbolic.test",
          first_name: "Oliver",
          last_name: "Smith",
          country: @country_gb,
          city: "London",
          address1: "221B Baker St",
          zipcode: "NW1 6XE"
        )

        profile = Affiliate::Profile.find_or_initialize_by(user: user)
        profile.referral_code = "oliver-creator"
        profile.commission_rate = 20.0
        profile.holding_days = 14
        profile.tenure_months = 12
        profile.currency = "GBP"
        profile.payouts_enabled = true
        profile.payment_method_type = :bank
        profile.payment_details = {}
        profile.save!(validate: false)

        apex_account = find_or_create_account(
          name: "Apex Studio",
          identifier: "apex-studio",
          currency: "GBP",
          owner_email: "team@apex-studio.test",
          owner_first_name: "Arthur",
          owner_last_name: "Pendleton"
        )
        referral_apex = Affiliate::Referral.find_or_create_by!(profile: profile, account: apex_account) do |r|
          r.status = :active
          r.created_at = 2.weeks.ago
        end

        seed_commission(profile: profile, referral: referral_apex, amount: 17.80, currency: "GBP", status: :available, created_at: 4.days.ago)

        profile
      end

      def clean_previous_test_runs!
        # Clean non-historical batches
        historical_batch = Affiliate::PayoutBatch.find_by(name: "Payout Run — Initial Batch")
        if historical_batch
          Affiliate::Payout.where.not(payout_batch_id: historical_batch.id).destroy_all
          Affiliate::PayoutBatch.where.not(id: historical_batch.id).destroy_all
        else
          Affiliate::Payout.destroy_all
          Affiliate::PayoutBatch.destroy_all
        end
      end

      def seed_historical_payout_batch!(profile1, profile2)
        batch = Affiliate::PayoutBatch.find_or_initialize_by(name: "Payout Run — Initial Batch")
        batch.status = :funded
        batch.provider = :manual
        batch.total_amount = 104.45
        batch.funded_at = 1.week.ago
        batch.created_at = 1.week.ago
        batch.save!

        paid_commission1 = Affiliate::Commission.find_by(affiliate_profile_id: profile1.id, status: :paid)
        if paid_commission1
          payout1 = Affiliate::Payout.find_or_initialize_by(affiliate_profile_id: profile1.id, payout_batch_id: batch.id)
          payout1.amount = paid_commission1.amount
          payout1.currency = profile1.currency
          payout1.status = :paid
          payout1.provider = :manual
          payout1.commission_ids = [paid_commission1.id]
          payout1.created_at = 1.week.ago
          payout1.save!
          Affiliates::Payouts::InvoiceGenerator.call(payout: payout1) unless payout1.invoice_pdf.attached?
        end

        paid_commission2 = Affiliate::Commission.find_by(affiliate_profile_id: profile2.id, status: :paid)
        if paid_commission2
          payout2 = Affiliate::Payout.find_or_initialize_by(affiliate_profile_id: profile2.id, payout_batch_id: batch.id)
          payout2.amount = paid_commission2.amount
          payout2.currency = profile2.currency
          payout2.status = :paid
          payout2.provider = :manual
          payout2.commission_ids = [paid_commission2.id]
          payout2.created_at = 1.week.ago
          payout2.save!
          Affiliates::Payouts::InvoiceGenerator.call(payout: payout2) unless payout2.invoice_pdf.attached?
        end
      end

      def seed_commission(profile:, referral:, amount:, currency: "USD", status: :available, created_at: Time.current)
        existing = Affiliate::Commission.find_by(
          profile: profile,
          referral: referral,
          amount: amount,
          status: status,
          currency: currency
        )
        return existing if existing

        raw_amount = (amount / (profile.commission_rate / 100.0)).round(2)
        transaction = Transaction.create!(
          account: referral.account,
          amount: raw_amount,
          currency: currency,
          transaction_type: :charge,
          status: :completed,
          provider: :stripe,
          created_at: created_at
        )

        commission = Affiliate::Commission.find_or_initialize_by(
          profile: profile,
          referral: referral,
          transaction_record: transaction
        )
        commission.amount = amount
        commission.original_amount = amount
        commission.currency = currency
        commission.original_currency = currency
        commission.status = status
        commission.commission_type = :normal
        commission.created_at = created_at
        commission.save!
        commission
      end

      def find_or_create_user(email:, first_name:, last_name:, country:, city:, address1:, zipcode:)
        address = Address.create!(
          country: country,
          city: city,
          address1: address1,
          zipcode: zipcode
        )

        user = User.find_or_initialize_by(email: email)
        user.first_name = first_name
        user.last_name = last_name
        user.name = "#{first_name} #{last_name}"
        user.display_name = "#{first_name} #{last_name}"
        user.address = address
        user.status = :active
        user.locale = "en"
        user.connection_token ||= SecureRandom.hex(16)

        if user.new_record?
          user.password = "password123"
          user.password_confirmation = "password123"
        end

        user.save!
        user
      end

      def find_or_create_account(name:, identifier:, currency: "USD", owner_email:, owner_first_name:, owner_last_name:)
        account = Account.find_by(identifier: identifier)
        return account if account

        country = case currency
        when "EUR" then @country_de
        when "GBP" then @country_gb
        else @country_us
        end

        address = Address.create!(
          country: country,
          city: "City",
          address1: "123 Business St",
          zipcode: "10001"
        )

        owner = User.find_or_initialize_by(email: owner_email)
        owner.first_name = owner_first_name
        owner.last_name = owner_last_name
        owner.name = "#{owner_first_name} #{owner_last_name}"
        owner.display_name = "#{owner_first_name} #{owner_last_name}"
        owner.address = address
        owner.status = :active
        owner.locale = "en"
        owner.connection_token ||= SecureRandom.hex(16)

        if owner.new_record?
          owner.password = "password123"
          owner.password_confirmation = "password123"
        end
        owner.save!

        account = Account.create!(
          name: name,
          identifier: identifier,
          currency: currency,
          referral_code: "REF-#{SecureRandom.hex(4).upcase}",
          status: :active
        )

        AccountUser.find_or_create_by!(account: account, user: owner) do |au|
          au.owner = true
          au.availability = :online
        end

        account
      end
    end
  end
end

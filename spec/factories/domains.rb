FactoryBot.define do
  factory :domain do
    account
    sequence(:value) { |n| "company#{n}" }
    name { "Test Portal" }
    domain_type { :subdomain }
    status { :active }
    dns_status { :dns_verified }
    ssl_status { :ssl_active }

    trait :subdomain do
      domain_type { :subdomain }
      sequence(:value) { |n| "company#{n}" }
      dns_status { :dns_verified }
      ssl_status { :ssl_active }
    end

    trait :custom do
      domain_type { :custom }
      sequence(:value) { |n| "support#{n}.example.com" }
      dns_status { :dns_unverified }
      ssl_status { :ssl_none }
      cname_target { Domain::CNAME_TARGET }
    end

    trait :dns_verified do
      dns_status { :dns_verified }
      dns_verified_at { Time.current }
    end

    trait :dns_pending do
      dns_status { :dns_pending }
    end

    trait :dns_failed do
      dns_status { :dns_failed }
    end

    trait :ssl_active do
      ssl_status { :ssl_active }
      ssl_added_at { Time.current }
      ssl_expires_at { 90.days.from_now }
    end

    trait :ssl_pending do
      ssl_status { :ssl_pending }
    end

    trait :ssl_expired do
      ssl_status { :ssl_expired }
      ssl_expires_at { 1.day.ago }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :suspended do
      status { :suspended }
    end
  end
end

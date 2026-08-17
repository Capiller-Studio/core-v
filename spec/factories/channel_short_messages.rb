FactoryBot.define do
  factory :channel_short_message, class: 'Channel::ShortMessage' do
    account
    name { "ShortMessage #{SecureRandom.hex(2)}" }
    full_phone_number { "+1#{SecureRandom.random_number(100_000_0000..999_999_9999)}" }
    phone_number { "#{SecureRandom.random_number(100_000_0000..999_999_9999)}" }
    phone_code { "+1" }
    service { :twilio }
    service_identifier { "sid_#{SecureRandom.hex(4)}" }
    short_message_type { :sms }
    status { :active }
    configurations { { "auth_token" => "test_twilio_auth_token", "token" => "test_signalwire_token" } }
    tokens { {} }
    data { {} }

    trait :twilio do
      service { :twilio }
      configurations { { "auth_token" => "test_twilio_auth_token" } }
    end

    trait :signalwire do
      service { :signalwire }
      configurations { { "token" => "test_signalwire_token" } }
    end

    trait :aws_sns do
      service { :aws_sns }
      configurations { {} }
    end
  end
end

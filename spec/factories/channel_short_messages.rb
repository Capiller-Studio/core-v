FactoryBot.define do
  factory :channel_short_message, class: 'Channel::ShortMessage' do
    account
    name { "ShortMessage #{SecureRandom.hex(2)}" }
    full_phone_number { "+123456789#{rand(100..999)}" }
    phone_number { "23456789#{rand(100..999)}" }
    phone_code { "+1" }
    service { :twilio }
    service_identifier { "sid_#{SecureRandom.hex(4)}" }
    short_message_type { :sms }
    status { :active }
    configurations { {} }
    tokens { {} }
    data { {} }
  end
end

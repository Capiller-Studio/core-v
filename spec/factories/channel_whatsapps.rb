FactoryBot.define do
  factory :channel_whatsapp, class: 'Channel::Whatsapp' do
    account
    full_phone_number { "+1#{SecureRandom.random_number(100_000_0000..999_999_9999)}" }
    phone_number_id { "pnid_#{SecureRandom.hex(4)}" }
    business_account_id { "baid_#{SecureRandom.hex(4)}" }
    api_key { "token_#{SecureRandom.hex(4)}" }
    status { :active }
    service { :cloud_api }
    configurations { {} }
    data { {} }
  end
end

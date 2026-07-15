FactoryBot.define do
  factory :channel_whatsapp, class: 'Channel::Whatsapp' do
    account
    full_phone_number { "+123456789#{rand(100..999)}" }
    phone_number_id { "pnid_#{SecureRandom.hex(4)}" }
    business_account_id { "baid_#{SecureRandom.hex(4)}" }
    api_key { "token_#{SecureRandom.hex(4)}" }
    status { :active }
    service { :cloud_api }
    configurations { {} }
    data { {} }
  end
end

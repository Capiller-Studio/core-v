FactoryBot.define do
  factory :channel_whatsapp, class: 'Channel::Whatsapp' do
    account
    sequence(:full_phone_number) { |n| "+12345678#{n}#{Time.now.to_i.to_s[-4..-1]}" }
    phone_number_id { "pnid_#{SecureRandom.hex(4)}" }
    business_account_id { "baid_#{SecureRandom.hex(4)}" }
    api_key { "token_#{SecureRandom.hex(4)}" }
    status { :active }
    service { :cloud_api }
    configurations { {} }
    data { {} }
  end
end

FactoryBot.define do
  factory :channel_instagram, class: 'Channel::Instagram' do
    account
    instagram_id { "ig_#{SecureRandom.hex(4)}" }
    access_token { "token_#{SecureRandom.hex(4)}" }
    expires_at { 30.days.from_now }
    name { "Instagram Page #{SecureRandom.hex(2)}" }
    status { :active }
    configurations { {} }
    data { {} }
  end
end

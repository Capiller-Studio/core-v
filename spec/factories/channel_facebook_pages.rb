FactoryBot.define do
  factory :channel_facebook_page, class: 'Channel::FacebookPage' do
    account
    page_identifier { "page_#{SecureRandom.hex(4)}" }
    access_token { "token_#{SecureRandom.hex(4)}" }
    user_access_token { "user_token_#{SecureRandom.hex(4)}" }
    name { "Facebook Page #{SecureRandom.hex(2)}" }
    status { :active }
    configurations { {} }
    data { {} }
  end
end

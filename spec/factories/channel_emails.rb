FactoryBot.define do
  factory :channel_email, class: 'Channel::Email' do
    account
    email { "support#{SecureRandom.hex(4)}@example.com" }
    forward_email { "forward#{SecureRandom.hex(4)}@example.com" }
  end
end

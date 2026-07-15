FactoryBot.define do
  factory :channel_custom, class: 'Channel::Custom' do
    account
    name { "Custom Channel #{SecureRandom.hex(4)}" }
    status { :active }
  end
end

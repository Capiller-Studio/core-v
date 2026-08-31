FactoryBot.define do
  factory :message_reaction do
    account
    message { association :message, account: account }
    sender { message.sender }
    emoji { "thumbs_up" }
    reaction_name { "thumbs_up" }
  end
end

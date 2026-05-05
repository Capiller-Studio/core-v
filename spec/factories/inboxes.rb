FactoryBot.define do
  factory :inbox do
    account
    name { 'Main Support' }
    association :channel, factory: :channel_email
    status { :active }
    configurations { {} }
    
    trait :web_widget do
      association :channel, factory: :channel_web_widget
    end
  end
end

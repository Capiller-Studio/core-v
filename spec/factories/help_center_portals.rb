FactoryBot.define do
  factory :help_center_portal, class: 'HelpCenter::Portal' do
    account
    domain { association :domain, account: account }
    name { "Support Portal" }
    default_locale { "en" }
    locales { ["en"] }
    status { :active }
    ui_configurations { {} }
    configurations { {} }
  end
end

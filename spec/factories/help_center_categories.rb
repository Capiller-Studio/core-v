# frozen_string_literal: true

FactoryBot.define do
  factory :help_center_category, class: 'HelpCenter::Category' do
    account
    portal { association :help_center_portal, account: account }
    name { 'General Category' }
    status { :active }
    visibility { :everyone }
    configurations { {} }
  end
end

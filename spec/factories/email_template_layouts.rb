# frozen_string_literal: true

FactoryBot.define do
  factory :email_template_layout do
    account
    name { 'Default Layout' }
  end
end

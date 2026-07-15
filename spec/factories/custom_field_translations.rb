FactoryBot.define do
  factory :custom_field_translation do
    custom_field
    locale { 'en' }
    options { [] }
  end
end

FactoryBot.define do
  factory :custom_field do
    account
    key { "key_#{SecureRandom.hex(4)}" }
    field_type { :text }
    entity_type { :customer }
    configurations { {} }
    validations { {} }
  end
end

FactoryBot.define do
  factory :custom_field_resource do
    custom_field
    resource { build(:customer) } # Just a default
    configurations { {} }
  end
end

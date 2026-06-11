# == Schema Information
#
# Table name: addresses
#
#  id                       :uuid             not null, primary key
#  name                     :string
#  title                    :string
#  address1                 :string
#  address2                 :string
#  city                     :string(60)
#  zipcode                  :string(15)
#  phone_code               :string
#  phone_number             :string
#  alternative_phone_code   :string
#  alternative_phone_number :string
#  state_name               :string
#  organization_name        :string
#  national_id              :string
#  description              :text
#  designation              :string
#  state_id                 :uuid
#  country_id               :uuid
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_addresses_on_country_id         (country_id)
#  index_addresses_on_created_at         (created_at)
#  index_addresses_on_name               (name)
#  index_addresses_on_organization_name  (organization_name)
#  index_addresses_on_state_id           (state_id)
#

FactoryBot.define do
  factory :address do
    address1 { FFaker::Address.street_address }
    city { FFaker::Address.city }
    zipcode { FFaker::AddressUS.zip_code }
    country
    state
  end
end

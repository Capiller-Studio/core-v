# == Schema Information
#
# Table name: states
#
#  id         :uuid             not null, primary key
#  abbr       :string
#  country_id :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_states_on_abbr        (abbr)
#  index_states_on_country_id  (country_id)
#  index_states_on_created_at  (created_at)
#

FactoryBot.define do
  factory :state do
    abbr { FFaker::AddressUS.state_abbr }
    country
  end
end

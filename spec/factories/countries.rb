FactoryBot.define do
  factory :country do
    sequence(:iso_name) { |n| "#{FFaker::Address.country} #{n} #{SecureRandom.hex(4)}" }
    sequence(:iso) { |n| "IS#{n}#{SecureRandom.alphanumeric(4)}".upcase }
    sequence(:iso3) { |n| "IS3#{n}#{SecureRandom.alphanumeric(4)}".upcase }
  end
end

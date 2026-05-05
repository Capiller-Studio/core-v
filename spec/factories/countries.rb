FactoryBot.define do
  factory :country do
    sequence(:iso_name) { |n| "#{FFaker::Address.country} #{n} #{SecureRandom.hex(4)}" }
    iso { SecureRandom.alphanumeric(2).upcase }
    iso3 { SecureRandom.alphanumeric(3).upcase }
  end
end

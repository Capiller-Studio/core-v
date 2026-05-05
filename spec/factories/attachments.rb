FactoryBot.define do
  factory :attachment do
    account
    association :resource, factory: :message
    attachment_type { :image }
  end
end

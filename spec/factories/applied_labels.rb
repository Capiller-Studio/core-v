FactoryBot.define do
  factory :applied_label do
    label
    association :labelable, factory: :conversation
  end
end

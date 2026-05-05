FactoryBot.define do
  factory :transaction do
    account
    subscription
    transaction_type { :charge }
    status { :completed }
    provider { :stripe }
    amount { 29.99 }
    currency { 'USD' }
    data { { "line_items" => [] } }
  end
end

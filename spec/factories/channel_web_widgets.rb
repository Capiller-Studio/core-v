FactoryBot.define do
  factory :channel_web_widget, class: 'Channel::WebWidget' do
    account
    name { "Web Widget #{SecureRandom.hex(4)}" }
    website_url { "https://example.com" }
    status { :active }
    configurations { {} }
    ui_configurations { {} }
    data { {} }
  end
end

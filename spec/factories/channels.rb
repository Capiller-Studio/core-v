FactoryBot.define do
  factory :channel_email, class: 'Channel::Email' do
    account
    sequence(:email) { |n| "support_#{n}_#{SecureRandom.hex(4)}@example.com" }
    name { 'Support Email' }
    configurations { {} }
    imap_configurations { {} }
    smtp_configurations { {} }
    status { :active }
  end

  factory :channel_web_widget, class: 'Channel::WebWidget' do
    account
    website_url { FFaker::Internet.http_url }
    website_token { SecureRandom.hex(32) }
    widget_color { '#2D89EF' }
    welcome_title { 'Hello!' }
    welcome_tagline { 'How can we help?' }
    status { :active }
    configurations { {} }
  end
end

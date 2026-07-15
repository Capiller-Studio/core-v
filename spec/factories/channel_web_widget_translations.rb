FactoryBot.define do
  factory :channel_web_widget_translation, class: 'Channel::WebWidgetTranslation' do
    web_widget { association(:channel_web_widget) }
    locale { 'en' }
  end
end

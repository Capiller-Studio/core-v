# frozen_string_literal: true

FactoryBot.define do
  factory :channel_mobile_widget, class: 'Channel::MobileWidget' do
    account
    name { "Mobile App #{SecureRandom.hex(4)}" }
    status { :active }
    configurations { {} }
    ui_configurations { { primary_color: "#0F766E" } }
    data { {} }
    anonymous_allowed { true }
    push_enabled { false }
    attachments_enabled { true }
  end

  factory :channel_mobile_widget_translation, class: 'Channel::MobileWidgetTranslation' do
    association :mobile_widget, factory: :channel_mobile_widget
    locale { 'es' }
    header_title { 'Soporte Móvil' }
    welcome_title { '¡Bienvenido!' }
    welcome_tagline { '¿Cómo podemos ayudarte?' }
  end
end

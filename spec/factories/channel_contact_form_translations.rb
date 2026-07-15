FactoryBot.define do
  factory :channel_contact_form_translation, class: 'Channel::ContactFormTranslation' do
    contact_form { association(:channel_contact_form) }
    locale { 'en' }
  end
end

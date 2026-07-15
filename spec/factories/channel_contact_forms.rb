FactoryBot.define do
  factory :channel_contact_form, class: 'Channel::ContactForm' do
    account
    name { "Contact Form #{SecureRandom.hex(4)}" }
    status { :active }
    configurations { {} }
  end
end

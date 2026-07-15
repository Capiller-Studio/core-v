require 'rails_helper'

RSpec.describe Channel::ContactFormTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:contact_form) }
  end

  describe 'Validations' do
    subject { create(:channel_contact_form_translation) }

    it { is_expected.to validate_presence_of(:locale) }
    it 'validates uniqueness of locale scoped to contact_form_id' do
      expect(subject).to be_valid
      duplicate = build(:channel_contact_form_translation, contact_form: subject.contact_form, locale: subject.locale)
      expect(duplicate).not_to be_valid
    end
  end

end

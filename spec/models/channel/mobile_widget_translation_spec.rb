# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::MobileWidgetTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:mobile_widget) }
  end

  describe 'Validations' do
    subject { create(:channel_mobile_widget_translation) }

    it { is_expected.to validate_presence_of(:locale) }

    it 'validates uniqueness of locale scoped to mobile_widget_id' do
      expect(subject).to be_valid
      duplicate = build(:channel_mobile_widget_translation, mobile_widget: subject.mobile_widget, locale: subject.locale)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:locale]).to be_present
    end

    it 'allows multiple translations with different locales for same mobile widget' do
      other_locale = build(:channel_mobile_widget_translation, mobile_widget: subject.mobile_widget, locale: 'fr')
      expect(other_locale).to be_valid
    end
  end
end

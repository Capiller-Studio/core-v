require 'rails_helper'

RSpec.describe Channel::WebWidgetTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:web_widget) }
  end

  describe 'Validations' do
    subject { create(:channel_web_widget_translation) }

    it { is_expected.to validate_presence_of(:locale) }
    
    it 'validates uniqueness of locale scoped to web_widget_id' do
      expect(subject).to be_valid
      duplicate = build(:channel_web_widget_translation, web_widget: subject.web_widget, locale: subject.locale)
      expect(duplicate).not_to be_valid
    end
  end

end

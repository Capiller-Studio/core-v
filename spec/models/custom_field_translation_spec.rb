require 'rails_helper'

RSpec.describe CustomFieldTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:custom_field) }
  end

  describe 'Validations' do
    subject { create(:custom_field_translation) }

    it { is_expected.to validate_presence_of(:locale) }
    
    it 'validates uniqueness of custom_field_id scoped to locale' do
      expect(subject).to be_valid
      duplicate = build(:custom_field_translation, custom_field: subject.custom_field, locale: subject.locale)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:custom_field_id]).to include('has already been taken')
    end
  end

end

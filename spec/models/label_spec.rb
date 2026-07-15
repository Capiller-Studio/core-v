require 'rails_helper'

RSpec.describe Label, type: :model do
  subject { build(:label) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:applied_labels).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:title) }
    
    it 'validates uniqueness of identifier scoped to account' do
      label = create(:label)
      new_label = build(:label, account: label.account, identifier: label.identifier)
      expect(new_label).not_to be_valid
      expect(new_label.errors[:identifier]).to include('has already been taken')
    end
  end

  describe 'Callbacks' do
    it 'generates an identifier from title' do
      label = build(:label, title: 'My Awesome Label', identifier: nil)
      label.validate
      expect(label.identifier).to eq('my-awesome-label')
    end
  end
end

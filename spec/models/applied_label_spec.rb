require 'rails_helper'

RSpec.describe AppliedLabel, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:label) }
    it { is_expected.to belong_to(:labelable) }
  end

  describe 'Validations' do
    it 'validates uniqueness of label scoped to labelable' do
      label = create(:label)
      conversation = create(:conversation)
      create(:applied_label, label: label, labelable: conversation)
      
      new_applied_label = build(:applied_label, label: label, labelable: conversation)
      expect(new_applied_label).not_to be_valid
      expect(new_applied_label.errors[:label_id]).to include('has already been taken')
    end
  end

  describe 'Callbacks' do
    it 'sets account_id from labelable before validation' do
      conversation = create(:conversation)
      label = create(:label, account: conversation.account)
      applied_label = build(:applied_label, label: label, labelable: conversation, account_id: nil)
      
      applied_label.validate
      expect(applied_label.account_id).to eq(conversation.account_id)
    end
  end
end

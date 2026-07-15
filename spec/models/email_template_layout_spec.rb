require 'rails_helper'

RSpec.describe EmailTemplateLayout, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:attachments) }
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to have_many(:email_templates) }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_many(:translations) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

end

require 'rails_helper'

RSpec.describe EmailTemplateLayoutTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:email_template_layout) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:body) }
  end

end

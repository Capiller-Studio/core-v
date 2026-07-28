require 'rails_helper'

RSpec.describe HelpCenter::ArticleTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:article) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:locale) }
    # Note: :title is not required — articles may have a draft_title instead
  end

end

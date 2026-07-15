require 'rails_helper'

RSpec.describe HelpCenter::ArticleReaction, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:article) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:reaction_type) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:reaction_type).with_values(happy: 0, neutral: 1, sad: 2) }
  end

end

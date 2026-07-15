require 'rails_helper'

RSpec.describe HelpCenter::Category, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:category_resources) }
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_one(:image_attachment) }
    it { is_expected.to have_one(:image_blob) }
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to have_many(:translations) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
    it { is_expected.to define_enum_for(:visibility).with_values(everyone: 0, unlisted: 1, internal: 2) }
  end

end

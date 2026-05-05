require 'rails_helper'

RSpec.describe Attachment, type: :model do
  subject { build(:attachment) }

  describe 'Associations' do
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:account) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:attachment_type).with_values(
      image: 0, file: 1, video: 2, audio: 3, location: 4, fallback: 5, 
      share: 6, story_mention: 7, contact: 8
    ) }
  end
end

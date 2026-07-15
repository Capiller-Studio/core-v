require 'rails_helper'

RSpec.describe SystemLog, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account).optional }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:event_key) }
    it { is_expected.to validate_presence_of(:log_level) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:log_level).with_values(info: 0, warn: 1, error: 2, debug: 3) }
  end

end

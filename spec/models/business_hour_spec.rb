require 'rails_helper'

RSpec.describe BusinessHour, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:business_hour_group) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:day_of_week).with_values(sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6) }
  end

  describe 'Validations' do
    it 'validates presence of times for weekly hours' do
      bh = build(:business_hour, day_of_week: :monday, opening_time: nil, closing_time: nil)
      expect(bh).not_to be_valid
      expect(bh.errors[:base]).to include("Opening and closing time must be present for weekly hours")
    end

    it 'validates opening time is before closing time' do
      bh = build(:business_hour, day_of_week: :monday, opening_time: '18:00', closing_time: '09:00')
      expect(bh).not_to be_valid
      expect(bh.errors[:closing_time]).to include("must be after opening time")
    end

    it 'validates presence of exception times' do
      bh = build(:business_hour, day_of_week: nil, close_from: nil, close_till: nil)
      expect(bh).not_to be_valid
      expect(bh.errors[:base]).to include("Close from and close till must be present for exceptions")
    end

    it 'validates close_from is before close_till' do
      bh = build(:business_hour, day_of_week: nil, close_from: Time.current + 1.hour, close_till: Time.current)
      expect(bh).not_to be_valid
      expect(bh.errors[:close_till]).to include("must be after close from")
    end
  end

  describe 'Callbacks' do
    it 'sets account_id from business_hour_group before validation' do
      bhg = create(:business_hour_group)
      bh = build(:business_hour, business_hour_group: bhg, account: nil, day_of_week: :monday, opening_time: '09:00', closing_time: '17:00')
      bh.validate
      expect(bh.account_id).to eq(bhg.account_id)
    end
  end

end

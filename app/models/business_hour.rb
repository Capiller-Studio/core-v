# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: business_hours
#
#  id                     :uuid             not null, primary key
#  close_from             :datetime
#  close_till             :datetime
#  closing_time           :time
#  configurations         :jsonb            not null
#  day_of_week            :integer
#  opening_time           :time
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#  business_hour_group_id :uuid             not null
#
# Indexes
#
#  index_business_hours_on_account_id                             (account_id)
#  index_business_hours_on_business_hour_group_id                 (business_hour_group_id)
#  index_business_hours_on_business_hour_group_id_and_created_at  (business_hour_group_id,created_at)
#  index_business_hours_on_close_time                             (business_hour_group_id,close_from,close_till)
#  index_business_hours_on_work_time                              (business_hour_group_id,day_of_week,opening_time,closing_time)
#
# Foreign Keys
#
#  fk_rails_...  (business_hour_group_id => business_hour_groups.id) ON DELETE => cascade
#
# rubocop:enable Layout/LineLength
class BusinessHour < ShardRecord
  belongs_to :account
  belongs_to :business_hour_group

  enum :day_of_week, { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }

  validate :validate_times

  before_validation :set_account_from_group, on: :create

  private

  def set_account_from_group
    self.account ||= business_hour_group&.account
  end

  def validate_times
    if day_of_week.present?
      if opening_time.blank? || closing_time.blank?
        errors.add(:base, "Opening and closing time must be present for weekly hours")
      elsif opening_time >= closing_time
        errors.add(:closing_time, "must be after opening time")
      end
    else
      if close_from.blank? || close_till.blank?
        errors.add(:base, "Close from and close till must be present for exceptions")
      elsif close_from >= close_till
        errors.add(:close_till, "must be after close from")
      end
    end
  end
end

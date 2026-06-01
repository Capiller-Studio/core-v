# frozen_string_literal: true

module AssignmentPolicies
  # Checks if the current time falls within the business hours schedule
  # of a given BusinessHourGroup.
  #
  # Handles:
  #   - Regular weekly schedules (day_of_week + opening_time/closing_time)
  #   - Holiday/closure periods (close_from/close_till date ranges)
  #
  # Returns true if currently within working hours, false otherwise.
  #
  class BusinessHoursChecker < ApplicationService
    attr_reader :business_hour_group, :time

    def initialize(business_hour_group:, time: Time.current)
      @business_hour_group = business_hour_group
      @time = time
    end

    def call
      return true unless business_hour_group

      # Check if current time falls within a closure/holiday period
      return false if during_closure?

      # Check if current time falls within regular business hours for today
      within_regular_hours?
    end

    private

    # Check if the current time is during a scheduled closure/holiday
    def during_closure?
      BusinessHour.where(
        business_hour_group: business_hour_group
      ).where(
        "close_from IS NOT NULL AND close_till IS NOT NULL AND close_from <= ? AND close_till >= ?",
        time, time
      ).exists?
    end

    # Check if the current time is within the regular opening hours for today's day of week
    def within_regular_hours?
      day = time.wday
      hours = BusinessHour.where(
        business_hour_group: business_hour_group,
        day_of_week: day
      ).where("opening_time IS NOT NULL AND closing_time IS NOT NULL")

      # No hours defined for today → not within business hours
      return false if hours.empty?

      current_time_str = time.strftime("%H:%M:%S")

      hours.any? do |bh|
        opening = bh.opening_time.strftime("%H:%M:%S")
        closing = bh.closing_time.strftime("%H:%M:%S")
        current_time_str >= opening && current_time_str <= closing
      end
    end
  end
end

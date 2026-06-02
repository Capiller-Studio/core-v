# frozen_string_literal: true

module Sla
  class TargetCalculator < ApplicationService
    attr_reader :sla_policy, :start_time, :limit_in_seconds

    def initialize(sla_policy:, start_time:, limit_in_seconds:)
      @sla_policy = sla_policy
      @start_time = start_time
      @limit_in_seconds = limit_in_seconds
    end

    def call
      return nil unless limit_in_seconds

      if sla_policy.during_working_hours? && sla_policy.business_hour_group.present?
        calculate_with_business_hours
      else
        start_time + limit_in_seconds.seconds
      end
    end

    private

    def calculate_with_business_hours
      current_time = start_time
      remaining_seconds = limit_in_seconds.to_i
      iterations = 0

      # Safety break to avoid infinite loops if no business hours are defined
      while remaining_seconds > 0 && iterations < 365
        iterations += 1

        day = current_time.wday
        hours = BusinessHour.where(
          business_hour_group: sla_policy.business_hour_group,
          day_of_week: day
        ).where("opening_time IS NOT NULL AND closing_time IS NOT NULL")

        if hours.empty? || during_closure?(current_time)
          # Skip to next day midnight
          current_time = (current_time + 1.day).beginning_of_day
          next
        end

        current_time_str = current_time.strftime("%H:%M:%S")
        
        # Find the active or next block of business hours for today
        active_block = hours.find do |bh|
          current_time_str >= bh.opening_time.strftime("%H:%M:%S") && current_time_str <= bh.closing_time.strftime("%H:%M:%S")
        end

        next_block = hours.select { |bh| bh.opening_time.strftime("%H:%M:%S") > current_time_str }.min_by { |bh| bh.opening_time.strftime("%H:%M:%S") }

        if active_block
          # We are inside a block. How many seconds left in this block?
          closing_time = Time.zone.parse("#{current_time.to_date} #{active_block.closing_time.strftime('%H:%M:%S')}")
          available_seconds = (closing_time - current_time).to_i

          if remaining_seconds <= available_seconds
            return current_time + remaining_seconds.seconds
          else
            remaining_seconds -= available_seconds
            current_time = closing_time
          end
        elsif next_block
          # Jump to the start of the next block today
          current_time = Time.zone.parse("#{current_time.to_date} #{next_block.opening_time.strftime('%H:%M:%S')}")
        else
          # No more blocks today, jump to tomorrow
          current_time = (current_time + 1.day).beginning_of_day
        end
      end

      current_time
    end

    def during_closure?(time)
      BusinessHour.where(
        business_hour_group: sla_policy.business_hour_group
      ).where(
        "close_from IS NOT NULL AND close_till IS NOT NULL AND close_from <= ? AND close_till >= ?",
        time, time
      ).exists?
    end
  end
end

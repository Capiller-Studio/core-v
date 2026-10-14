# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Business Hours and Modules Integration End-To-End', type: :service do
  let(:account) { create(:account) }
  let(:timezone) { 'Eastern Time (US & Canada)' }
  let(:business_hour_group) do
    create(:business_hour_group,
      account: account,
      name: 'Standard Eastern Support',
      timezone: timezone
    )
  end

  around do |example|
    Time.use_zone(timezone, &example)
  end

  # Create schedule: Mon-Fri 09:00 to 17:00, weekends closed
  before do
    %i[monday tuesday wednesday thursday friday].each do |day|
      create(:business_hour,
        account: account,
        business_hour_group: business_hour_group,
        day_of_week: day,
        opening_time: '09:00:00',
        closing_time: '17:00:00'
      )
    end
  end

  describe 'Module Integration 1: SLA Target Calculation' do
    let(:sla_policy) do
      create(:sla_policy,
        account: account,
        name: 'Business Hours SLA',
        during_working_hours: true,
        business_hour_group: business_hour_group
      )
    end

    it 'accurately calculates target deadline pausing over non-working hours and weekends' do
      # Friday 2026-10-16 at 16:30:00 EDT (30 mins before closing)
      Time.use_zone(timezone) do
        friday_afternoon = Time.zone.parse('2026-10-16 16:30:00')
        one_hour_limit = 3600 # 1 hour

        calculator = Sla::TargetCalculator.new(
          sla_policy: sla_policy,
          start_time: friday_afternoon,
          limit_in_seconds: one_hour_limit
        )

        target_time = calculator.call

        # 30 mins used on Friday (16:30 - 17:00).
        # Saturday & Sunday are skipped.
        # Monday resumes at 09:00:00, remaining 30 mins -> Monday 09:30:00
        expect(target_time).to eq(Time.zone.parse('2026-10-19 09:30:00'))
      end
    end

    it 'does not skip hours when SLA policy does not enable working hours constraint' do
      sla_24_7 = create(:sla_policy,
        account: account,
        name: '24/7 SLA',
        during_working_hours: false,
        business_hour_group: nil
      )

      Time.use_zone(timezone) do
        friday_afternoon = Time.zone.parse('2026-10-16 16:30:00')
        one_hour_limit = 3600

        calculator = Sla::TargetCalculator.new(
          sla_policy: sla_24_7,
          start_time: friday_afternoon,
          limit_in_seconds: one_hour_limit
        )

        # 24/7 adds 1 hour directly without pausing
        expect(calculator.call).to eq(Time.zone.parse('2026-10-16 17:30:00'))
      end
    end
  end

  describe 'Module Integration 2: Assignment Policies Business Hours Checker' do
    let(:assignment_policy) do
      create(:assignment_policy,
        account: account,
        name: 'Working Hours Auto-Assign',
        respect_business_hours: true,
        business_hour_group: business_hour_group
      )
    end

    it 'permits routing during active working hours' do
      Time.use_zone(timezone) do
        # Wednesday at 11:00 AM (inside 09:00 - 17:00)
        active_work_time = Time.zone.parse('2026-10-14 11:00:00')
        is_active = AssignmentPolicies::BusinessHoursChecker.call(
          business_hour_group: business_hour_group,
          time: active_work_time
        )
        expect(is_active).to be(true)
        expect(assignment_policy.within_business_hours?(time: active_work_time)).to be(true)
      end
    end

    it 'blocks routing outside of working hours and on closed weekend days' do
      Time.use_zone(timezone) do
        # Wednesday evening at 20:00 (after 17:00 closing)
        evening_time = Time.zone.parse('2026-10-14 20:00:00')
        expect(AssignmentPolicies::BusinessHoursChecker.call(
          business_hour_group: business_hour_group,
          time: evening_time
        )).to be(false)

        # Saturday at 12:00 PM (weekend closed)
        weekend_time = Time.zone.parse('2026-10-17 12:00:00')
        expect(AssignmentPolicies::BusinessHoursChecker.call(
          business_hour_group: business_hour_group,
          time: weekend_time
        )).to be(false)
        expect(assignment_policy.within_business_hours?(time: weekend_time)).to be(false)
      end
    end

    it 'respects holiday and closure exception windows' do
      # Add holiday closure on Thursday 2026-10-15 all day
      create(:business_hour,
        account: account,
        business_hour_group: business_hour_group,
        day_of_week: nil,
        close_from: Time.zone.parse('2026-10-15 00:00:00'),
        close_till: Time.zone.parse('2026-10-15 23:59:59')
      )

      Time.use_zone(timezone) do
        holiday_time = Time.zone.parse('2026-10-15 11:00:00')
        expect(AssignmentPolicies::BusinessHoursChecker.call(
          business_hour_group: business_hour_group,
          time: holiday_time
        )).to be(false)
      end
    end
  end

  describe 'Module Integration 3: Edge Cases and Fallbacks' do
    it 'returns true if business hour group is not configured on policy' do
      unrestricted_policy = create(:assignment_policy,
        account: account,
        name: 'Unrestricted Policy',
        respect_business_hours: false,
        business_hour_group: nil
      )

      expect(unrestricted_policy.within_business_hours?).to be(true)
      expect(AssignmentPolicies::BusinessHoursChecker.call(business_hour_group: nil)).to be(true)
    end
  end
end

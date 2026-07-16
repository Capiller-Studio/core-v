require 'rails_helper'

RSpec.describe Sla::TargetCalculator do
  let(:start_time) { Time.zone.parse('2023-01-01 10:00:00') }
  let(:limit_in_seconds) { 3600 } # 1 hour
  let(:business_hour_group) { double('BusinessHourGroup') }
  
  describe '#call' do
    it 'returns nil if limit_in_seconds is nil' do
      service = described_class.new(sla_policy: double, start_time: start_time, limit_in_seconds: nil)
      expect(service.call).to be_nil
    end

    context 'when not using business hours' do
      let(:sla_policy) { double('SlaPolicy', during_working_hours?: false) }
      let(:service) { described_class.new(sla_policy: sla_policy, start_time: start_time, limit_in_seconds: limit_in_seconds) }

      it 'adds seconds directly to start time' do
        expect(service.call).to eq(Time.zone.parse('2023-01-01 11:00:00'))
      end
    end

    context 'when using business hours' do
      let(:sla_policy) { double('SlaPolicy', during_working_hours?: true, business_hour_group: business_hour_group) }
      let(:service) { described_class.new(sla_policy: sla_policy, start_time: start_time, limit_in_seconds: limit_in_seconds) }

      before do
        stub_const('BusinessHour', double('BusinessHourClass'))
        allow(BusinessHour).to receive(:where).and_return(double(where: double(exists?: false)))
      end

      it 'calculates time if within active block' do
        bh_scope = double('BHScope')
        allow(BusinessHour).to receive(:where).with(business_hour_group: business_hour_group, day_of_week: start_time.wday).and_return(bh_scope)
        
        bh = double('BusinessHour', opening_time: Time.parse('09:00:00'), closing_time: Time.parse('17:00:00'))
        allow(bh_scope).to receive(:where).with("opening_time IS NOT NULL AND closing_time IS NOT NULL").and_return([bh])
        
        # 10:00 + 1 hour = 11:00, within 09:00-17:00
        expect(service.call).to eq(Time.zone.parse('2023-01-01 11:00:00'))
      end

      it 'skips to next day if no business hours today' do
        bh_scope1 = double('BHScope1')
        bh_scope2 = double('BHScope2')
        
        allow(BusinessHour).to receive(:where).with(business_hour_group: business_hour_group, day_of_week: start_time.wday).and_return(bh_scope1)
        allow(bh_scope1).to receive(:where).and_return([])

        next_day = (start_time + 1.day).beginning_of_day
        
        allow(BusinessHour).to receive(:where).with(business_hour_group: business_hour_group, day_of_week: next_day.wday).and_return(bh_scope2)
        bh = double('BusinessHour', opening_time: Time.parse('09:00:00'), closing_time: Time.parse('17:00:00'))
        allow(bh_scope2).to receive(:where).and_return([bh])

        expect(service.call).to eq(next_day.change(hour: 10, min: 0)) # starts at 9am, adds 1 hour
      end
    end
  end
end

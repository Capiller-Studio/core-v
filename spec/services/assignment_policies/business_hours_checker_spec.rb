require 'rails_helper'

RSpec.describe AssignmentPolicies::BusinessHoursChecker do
  let(:business_hour_group) { double('BusinessHourGroup', id: 'bhg_1') }
  let(:time) { Time.zone.parse('2026-07-16 10:00:00') } # Thursday
  let(:service) { described_class.new(business_hour_group: business_hour_group, time: time) }

  before do
    stub_const('BusinessHour', double('BusinessHourClass'))
  end

  describe '#call' do
    it 'returns true if business_hour_group is nil' do
      service = described_class.new(business_hour_group: nil)
      expect(service.call).to be true
    end

    context 'when during closure' do
      let(:closure_scope) { double('ClosureScope', exists?: true) }
      let(:group_scope) { double('GroupScope') }

      before do
        allow(BusinessHour).to receive(:where).with(business_hour_group: business_hour_group).and_return(group_scope)
        allow(group_scope).to receive(:where).with("close_from IS NOT NULL AND close_till IS NOT NULL AND close_from <= ? AND close_till >= ?", time, time).and_return(closure_scope)
      end

      it 'returns false' do
        expect(service.call).to be false
      end
    end

    context 'when not during closure' do
      let(:closure_scope) { double('ClosureScope', exists?: false) }
      let(:group_scope) { double('GroupScope') }
      let(:hours_scope) { double('HoursScope') }

      before do
        allow(BusinessHour).to receive(:where).with(business_hour_group: business_hour_group).and_return(group_scope)
        allow(group_scope).to receive(:where).with("close_from IS NOT NULL AND close_till IS NOT NULL AND close_from <= ? AND close_till >= ?", time, time).and_return(closure_scope)
        
        allow(BusinessHour).to receive(:where).with(business_hour_group: business_hour_group, day_of_week: time.wday).and_return(group_scope)
        allow(group_scope).to receive(:where).with("opening_time IS NOT NULL AND closing_time IS NOT NULL").and_return(hours_scope)
      end

      it 'returns false if no hours defined for today' do
        allow(hours_scope).to receive(:empty?).and_return(true)
        expect(service.call).to be false
      end

      it 'returns true if within regular hours' do
        allow(hours_scope).to receive(:empty?).and_return(false)
        
        bh = double('BusinessHour', opening_time: Time.zone.parse('09:00:00'), closing_time: Time.zone.parse('17:00:00'))
        allow(hours_scope).to receive(:any?).and_yield(bh)
        
        expect(service.call).to be true
      end

      it 'returns false if outside regular hours' do
        allow(hours_scope).to receive(:empty?).and_return(false)
        
        bh = double('BusinessHour', opening_time: Time.zone.parse('11:00:00'), closing_time: Time.zone.parse('17:00:00'))
        allow(hours_scope).to receive(:any?).and_yield(bh)
        
        expect(service.call).to be false
      end
    end
  end
end

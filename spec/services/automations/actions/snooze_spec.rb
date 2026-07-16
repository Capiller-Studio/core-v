require 'rails_helper'

RSpec.describe Automations::Actions::Snooze do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :active) }

  describe '#call' do
    context 'when duration_hours is invalid' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { duration_hours: 0 }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('duration_hours must be positive')
      end
    end

    context 'with valid parameters' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { duration_hours: 24 }) }

      it 'updates status and snoozed_until in configurations' do
        freeze_time do
          service.call
          conversation.reload
          expect(conversation.status).to eq('snoozed')
          expect(conversation.configurations["snoozed_until"]).to eq(24.hours.from_now.iso8601)
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Automations::Actions::AssignTeam do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:team) { create(:team, account: account) }

  describe '#call' do
    context 'when team is not found' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { team_id: 999999 }) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when team is found' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { team_id: team.id }) }

      before do
        stub_const('Teams::AssignmentService', double('AssignmentService'))
      end

      it 'calls Teams::AssignmentService' do
        expect(Teams::AssignmentService).to receive(:call).with(
          conversation: conversation,
          team: team
        )
        service.call
      end
    end
  end
end

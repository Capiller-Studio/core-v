require 'rails_helper'

RSpec.describe Teams::DestroyService do
  let(:account) { create(:account) }
  let(:team) { create(:team, account: account) }
  let(:service) { described_class.new(team: team) }

  describe '#call' do
    context 'when feature is enabled' do
      before do
        allow(account).to receive(:feature_enabled?) { |feature| feature == :teams }
        # We need to stub team.account.feature_enabled? to return true
        allow(team).to receive(:account).and_return(account)
      end

      it 'destroys the team and nullifies conversation team_ids' do
        conversation = create(:conversation, account: account, team: team)
        
        expect { service.call }.to change(Team, :count).by(-1)
        
        expect(conversation.reload.team_id).to be_nil
      end
    end

    context 'when feature is not enabled' do
      before do
        allow(team).to receive(:account).and_return(account)
        allow(account).to receive(:feature_enabled?).with(:teams).and_return(false)
      end

      it 'raises an error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotSaved, /Teams feature is not enabled/)
      end
    end
  end
end

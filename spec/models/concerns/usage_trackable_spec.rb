# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsageTrackable, type: :model do
  let(:plan) { create(:plan, limits: { 'teams' => 2 }) }
  let(:account) { create(:account, limits: { 'teams' => { 'current' => 1 } }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  describe 'usage tracking and limit enforcement' do
    it 'increments usage on create' do
      expect {
        create(:team, account: account)
      }.to change { account.current_usage('teams') }.from(1).to(2)
    end

    it 'blocks creation when limit is reached' do
      create(:team, account: account) # Reaches limit of 2

      team = build(:team, account: account)
      expect(team.save).to be(false)
      expect(team.errors[:base]).to include('Teams limit reached for your plan. Please upgrade.')
    end

    it 'decrements usage on destroy' do
      team = create(:team, account: account)
      expect {
        team.destroy
      }.to change { account.current_usage('teams') }.by(-1)
    end
  end

  describe 'when system_provided' do
    let(:plan) { create(:plan, limits: { 'macros' => 1 }) }
    let(:account) { create(:account, limits: { 'macros' => { 'current' => 1 } }) }
    let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

    it 'bypasses limit enforcement and usage tracking for system resources' do
      expect {
        system_macro = create(:macro, account: account, system_provided: true)
        expect(system_macro).to be_persisted
      }.not_to(change { account.current_usage('macros') })
    end
  end

  describe 'i18n error messages' do
    it 'translates limit error messages dynamically via I18n' do
      create(:team, account: account)
      team = build(:team, account: account)
      team.save

      expected_message = I18n.t('activerecord.errors.messages.limit_reached', resource: I18n.t('resources.teams'))
      expect(team.errors[:base]).to include(expected_message)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSetting, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'flag defaults and checks' do
    let(:setting) do
      account.with_shard do
        described_class.create!(account: account, user: user)
      end
    end

    it 'enables default flags on creation' do
      expect(setting.email_enabled_for?(:conversation_created)).to be(true)
      expect(setting.push_enabled_for?(:conversation_assigned)).to be(true)
    end

    it 'allows disabling specific notifications' do
      setting.email_conversation_created = false
      setting.save!

      expect(setting.email_enabled_for?(:conversation_created)).to be(false)
    end
  end
end

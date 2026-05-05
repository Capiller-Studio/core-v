require 'rails_helper'

RSpec.describe Inbox, type: :model do
  subject { build(:inbox) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:channel) }
    it { is_expected.to have_many(:conversations).dependent(:destroy) }
    it { is_expected.to have_many(:inbox_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:inbox_users) }
    it { is_expected.to have_many(:customers).through(:customer_inboxes) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
  end

  describe '#auto_assign?' do
    it 'returns true by default' do
      inbox = build(:inbox)
      expect(inbox.auto_assign?).to be true
    end

    it 'returns false when disabled in configurations' do
      inbox = build(:inbox, configurations: { 'auto_assign' => false })
      expect(inbox.auto_assign?).to be false
    end
  end

  describe 'Callbacks' do
    it 'cleans up integration settings after destroy' do
      inbox = create(:inbox)
      integration = create(:integration, account: inbox.account, settings: { 'subscribed_inboxes' => [ inbox.id ] })

      inbox.destroy
      integration.reload
      expect(integration.settings['subscribed_inboxes']).not_to include(inbox.id)
    end
  end
end

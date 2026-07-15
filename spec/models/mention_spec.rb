require 'rails_helper'

RSpec.describe Mention, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:mentioned) }
    it { is_expected.to belong_to(:resource) }
  end

  describe '#mark_as_read!' do
    it 'updates read_at and calls UnreadCounts::Reset' do
      account = create(:account)
      conversation = create(:conversation, account: account)
      user = create(:user)
      mention = create(:mention, account: account, resource: conversation, mentioned: user)

      allow(UnreadCounts::Reset).to receive(:call)
      
      Timecop.freeze do
        mention.mark_as_read!
        expect(mention.reload.read_at.to_i).to eq(Time.current.to_i)
        expect(UnreadCounts::Reset).to have_received(:call).with(mention, user)
      end
    end
  end
end

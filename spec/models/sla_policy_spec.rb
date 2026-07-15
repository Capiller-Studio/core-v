require 'rails_helper'

RSpec.describe SlaPolicy, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:business_hour_group).optional }
    it { is_expected.to have_many(:conversation_slas) }
    it { is_expected.to have_many(:conversations) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_many(:sla_inboxes) }
  end

end

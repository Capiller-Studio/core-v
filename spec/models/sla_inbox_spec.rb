require 'rails_helper'

RSpec.describe SlaInbox, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:sla_policy) }
  end

end

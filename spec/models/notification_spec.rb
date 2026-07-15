require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:event).with_values(conversation_created: 0, conversation_assigned: 1, conversation_resolved: 2, sla_breached: 3, message_created: 4, conversation_mention: 5, subscription_created: 6, subscription_renewed: 7, subscription_cancelled: 8, trial_expiring: 9, payment_failed: 10, limit_approaching: 11, limit_reached: 12, team_assigned: 13) }
  end

end

require 'rails_helper'

RSpec.describe Channel::ShortMessage, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_one(:primary_inbox) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
    it { is_expected.to define_enum_for(:service).with_values(twilio: 0, signalwire: 1, aws_sns: 2) }
    it { is_expected.to define_enum_for(:short_message_type).with_values(sms: 0) }
  end

end

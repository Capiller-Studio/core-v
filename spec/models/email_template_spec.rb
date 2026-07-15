require 'rails_helper'

RSpec.describe EmailTemplate, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:attachments) }
    it { is_expected.to have_one(:current_translation) }
    it { is_expected.to belong_to(:email_template_layout).optional }
    it { is_expected.to have_one(:fallback_translation) }
    it { is_expected.to have_many(:translations) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:template_type) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:template_type).with_values(conversation_reply: 0, agent_notification: 1, welcome_email: 2, password_reset: 3, email_verification: 4, team_invitation: 5, csat_survey: 6) }
    it { is_expected.to define_enum_for(:status).with_values(inactive: 0, active: 1) }
  end

end

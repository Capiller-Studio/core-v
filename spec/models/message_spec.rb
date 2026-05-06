require 'rails_helper'

RSpec.describe Message, type: :model do
  subject { build(:message) }

  describe 'Associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:sender) }
    it { is_expected.to have_many(:attachments).dependent(:destroy) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(sent: 0, delivered: 1, read: 2, failed: 3) }
    it { is_expected.to define_enum_for(:content_type).with_values(text: 0, input_email: 1, activity: 2, template: 3, input_csat: 4) }
    it { is_expected.to define_enum_for(:visibility).with_values(personal: 0, global: 1) }
    it { is_expected.to define_enum_for(:source).with_values(email: 0, facebook: 1, whatsapp: 2, instagram: 3, api: 4, web_widget: 5, sms: 6, telegram: 7, help_center: 8).with_suffix(:source) }
  end

  describe '#incoming?' do
    it 'returns true when sender is a Customer' do
      message = build(:message, sender: build(:customer))
      expect(message.incoming?).to be true
    end

    it 'returns false when sender is a User' do
      message = build(:message, sender: build(:user))
      expect(message.incoming?).to be false
    end
  end

  describe '#outgoing?' do
    it 'returns true when sender is a User' do
      message = build(:message, sender: build(:user))
      expect(message.outgoing?).to be true
    end

    it 'returns false when sender is a Customer' do
      message = build(:message, sender: build(:customer))
      expect(message.outgoing?).to be false
    end
  end
end

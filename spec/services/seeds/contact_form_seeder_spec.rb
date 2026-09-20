require 'rails_helper'

RSpec.describe Seeds::ContactFormSeeder do
  let(:account) { create(:account) }

  before do
    allow(Accounts::DefaultCustomFieldsCreator).to receive(:call)
    # create some custom fields to test custom_field_resources association
    create_list(:custom_field, 2, account: account)
  end

  describe '.seed' do
    it 'creates a ContactForm channel, an inbox, and associates custom fields' do
      expect {
        described_class.seed(account)
      }.to change { Channel::ContactForm.count }.by(1)
       .and change { Inbox.count }.by(1)

      channel = Channel::ContactForm.find_by(account_id: account.id, name: 'General Contact Form')
      expect(channel).not_to be_nil
      expect(channel.name).to eq('General Contact Form')
      expect(channel.account).to eq(account)
      expect(channel.configurations['primary_color']).to eq('#10B981')
      expect(channel.require_login).to eq(false)
      expect(channel.allow_attachments).to eq(true)
      expect(channel.send_confirmation_email).to eq(true)

      inbox = channel.inboxes.last
      expect(inbox.name).to eq('Contact Form Inbox')
      expect(inbox.account).to eq(account)
      expect(inbox.primary_inbox).to eq(true)
      expect(channel.primary_inbox).to eq(inbox)

      expect(Accounts::DefaultCustomFieldsCreator).to have_received(:call).with(account: account).at_least(:once)

      expect(channel.custom_field_resources.count).to eq(2)
      expect(channel.custom_field_resources.pluck(:position)).to contain_exactly(1, 2)
    end

    it 'is idempotent' do
      described_class.seed(account)

      expect {
        described_class.seed(account)
      }.to change { Channel::ContactForm.count }.by(0)
       .and change { Inbox.count }.by(0)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Automations::EmailDeliveryWorker, type: :worker do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:customer) { create(:customer, account: account, name: 'Alice Customer', email: 'alice@example.com') }
  let(:conversation) { create(:conversation, account: account, assignee: user) }
  let(:email_template) do
    create(:email_template,
      account: account,
      name: 'Welcome',
      subject: 'Welcome to Capiller Rely',
      body: '<p>Hello {{ customer.name }} from {{ account.name }}</p>'
    )
  end

  describe '#perform' do
    it 'renders liquid template, creates message, and enqueues Messages::DeliveryWorker' do
      expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String))

      expect {
        described_class.new.perform(email_template.id, customer.id, conversation.id, account.id)
      }.to change { conversation.messages.count }.by(1)

      message = conversation.messages.last
      expect(message.content).to include("Hello Alice Customer from #{account.name}")
      expect(message.data['email_template_id']).to eq(email_template.id)
      expect(message.data['target_email']).to eq('alice@example.com')
    end

    it 'returns early if template or customer is missing' do
      expect(Messages::DeliveryWorker).not_to receive(:perform_async)

      described_class.new.perform(SecureRandom.uuid, customer.id, conversation.id, account.id)
    end
  end
end

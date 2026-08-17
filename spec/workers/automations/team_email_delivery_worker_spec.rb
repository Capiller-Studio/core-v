# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Automations::TeamEmailDeliveryWorker, type: :worker do
  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'bob@example.com') }
  let(:customer) { create(:customer, account: account, name: 'Alice Customer') }
  let(:conversation) { create(:conversation, account: account, assignee: user) }
  let(:email_template) do
    create(:email_template,
      account: account,
      name: 'Team Alert',
      subject: 'Urgent ticket for {{ user.name }}',
      body: '<p>Please check ticket {{ account.name }}</p>'
    )
  end

  let(:system_mailer_class) do
    Class.new do
      def self.custom_email(*); end
    end
  end

  before do
    stub_const('SystemMailer', system_mailer_class)
  end

  describe '#perform' do
    it 'renders template and delivers internal email via SystemMailer' do
      mail_double = double('mail', deliver_later: true)
      expect(SystemMailer).to receive(:custom_email).with(
        to: 'bob@example.com',
        subject: "Urgent ticket for #{user.name}",
        body: '<p>Please check ticket ' + account.name + '</p>'
      ).and_return(mail_double)

      described_class.new.perform(email_template.id, user.id, conversation.id, account.id)
    end

    it 'returns early if template or user is not found' do
      expect(SystemMailer).not_to receive(:custom_email)

      described_class.new.perform(SecureRandom.uuid, user.id, conversation.id, account.id)
    end
  end
end

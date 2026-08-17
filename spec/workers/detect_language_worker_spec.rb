# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DetectLanguageWorker, type: :worker do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account, locale: 'en') }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: customer, content: 'Bonjour, j ai besoin d aide') }

  describe '#perform' do
    it 'detects language from customer message and updates customer and conversation locales' do
      allow(Integrations::LanguageDetectors::Engine).to receive(:call).with(
        text: message.content,
        account: account
      ).and_return('fr')

      allow(::Utilities::LocaleParser).to receive(:parse).with('fr').and_return('fr')

      described_class.new.perform(account.id, message.id)

      customer.reload
      conversation.reload
      expect(customer.locale).to eq('fr')
      expect(conversation.locale).to eq('fr')
    end

    it 'skips if customer already has a non-English locale set' do
      customer.update!(locale: 'de')
      expect(Integrations::LanguageDetectors::Engine).not_to receive(:call)

      described_class.new.perform(account.id, message.id)
    end

    it 'skips if message sender is not a Customer' do
      agent_user = create(:user)
      agent_msg = create(:message, account: account, conversation: conversation, sender: agent_user)
      expect(Integrations::LanguageDetectors::Engine).not_to receive(:call)

      described_class.new.perform(account.id, agent_msg.id)
    end

    it 'raises MutexLockError if mutex lock fails to allow Sidekiq retry' do
      stub_const('MutexLockError', Class.new(StandardError))
      allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_raise(MutexLockError.new('Locked'))

      expect {
        described_class.new.perform(account.id, message.id)
      }.to raise_error(MutexLockError)
    end
  end
end

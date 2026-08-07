require 'rails_helper'

RSpec.describe DetectLanguageWorker, type: :worker do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account, locale: 'en') }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: customer, content: 'Bonjour tout le monde') }

  describe '#perform' do
    it 'updates customer and conversation locale if language is detected' do
      allow(Integrations::LanguageDetectors::Engine).to receive(:call).and_return('fr')
      allow(Utilities::LocaleParser).to receive(:parse).with('fr').and_return('fr')

      described_class.new.perform(account.id, message.id)

      expect(customer.reload.locale).to eq('fr')
      expect(conversation.reload.locale).to eq('fr')
    end

    it 'does not update locale if customer already has a non-English locale' do
      customer.update!(locale: 'es')
      
      expect(Integrations::LanguageDetectors::Engine).not_to receive(:call)

      described_class.new.perform(account.id, message.id)
      
      expect(customer.reload.locale).to eq('es')
    end

    it 'does not update locale if language is English and customer locale is English' do
      customer.update!(locale: 'en')
      allow(Integrations::LanguageDetectors::Engine).to receive(:call).and_return('en')
      allow(Utilities::LocaleParser).to receive(:parse).with('en').and_return('en')

      described_class.new.perform(account.id, message.id)

      expect(customer.reload.locale).to eq('en')
    end
    
    it 'rescues and logs errors' do
      allow(Account).to receive(:find_by).and_raise(StandardError.new("Database error"))
      expect(Rails.logger).to receive(:error).with(/DetectLanguageWorker Error/)
      
      expect { described_class.new.perform(account.id, message.id) }.not_to raise_error
    end
  end
end

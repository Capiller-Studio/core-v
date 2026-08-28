require 'rails_helper'

RSpec.describe Integrations::Translators::Engine do
  let(:account) { double('Account') }
  let(:message) { double('Message', content: 'Hola mundo', account: account, data: {}) }
  let(:service) { described_class.new(message: message, target_locale: 'en') }

  describe '#call' do
    context 'when translation already exists' do
      let(:message) { double('Message', content: 'Hola mundo', account: account, data: { "translation" => { "en" => "Hello world" } }) }

      it 'returns existing translation without API call' do
        expect(HTTParty).not_to receive(:post)
        expect(service.call).to eq("Hello world")
      end
    end

    context 'with google translate integration' do
      let(:integrations_scope) { double('IntegrationsScope') }
      let(:google_integration) { double('Integration', credentials: { "api_key" => "secret_key" }) }

      before do
        allow(account).to receive(:integrations).and_return(integrations_scope)
        allow(integrations_scope).to receive(:find_by).with(provider: :google_translate, status: :active).and_return(google_integration)
      end

      it 'calls google API and updates message data' do
        response = double('Response', success?: true, parsed_response: { "data" => { "translations" => [{ "translatedText" => "Hello world" }] } })
        
        expect(HTTParty).to receive(:post).with(
          "https://translation.googleapis.com/language/translate/v2",
          hash_including(
            body: { q: 'Hola mundo', target: 'en', key: 'secret_key' }.to_json
          )
        ).and_return(response)

        expect(message).to receive(:update!).with(data: { "translation" => { "en" => "Hello world" } })

        expect(service.call).to eq("Hello world")
      end
    end

    context 'with libre translate fallback' do
      let(:integrations_scope) { double('IntegrationsScope') }

      before do
        allow(account).to receive(:integrations).and_return(integrations_scope)
        allow(integrations_scope).to receive(:find_by).with(provider: :google_translate, status: :active).and_return(nil)
        ENV['OS_TRANSLATOR_URL'] = 'http://localhost:5001/translate'
      end

      after do
        ENV.delete('OS_TRANSLATOR_URL')
      end

      it 'calls libre translate and updates message data' do
        response = double('Response', success?: true, parsed_response: { "translatedText" => "Hello world" })
        
        expect(HTTParty).to receive(:post).with(
          'http://localhost:5001/translate',
          hash_including(
            body: { q: 'Hola mundo', source: 'auto', target: 'en', format: 'html' }.to_json
          )
        ).and_return(response)

        expect(message).to receive(:update!).with(data: { "translation" => { "en" => "Hello world" } })

        expect(service.call).to eq("Hello world")
      end

      it 'returns nil on failure' do
        response = double('Response', success?: false, code: 500, body: 'Error')
        
        allow(HTTParty).to receive(:post).and_return(response)
        expect(Rails.logger).to receive(:error).with(/LibreTranslate Error: 500 - Error/)
        expect(message).not_to receive(:update!)

        expect(service.call).to be_nil
      end
    end

    context 'when error occurs' do
      it 'rescues and logs' do
        allow(account).to receive(:integrations).and_raise(StandardError.new("Network Error"))
        expect(Rails.logger).to receive(:error).with(/Translation Engine Failed dynamically: Network Error/)
        
        result = nil
        expect { result = service.call }.not_to raise_error
        expect(result).to be_nil
      end
    end
  end
end

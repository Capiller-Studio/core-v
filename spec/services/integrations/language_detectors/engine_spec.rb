require 'rails_helper'

RSpec.describe Integrations::LanguageDetectors::Engine do
  let(:account) { create(:account) }
  let(:text) { "Hola mundo" }
  let(:service) { described_class.new(text: text, account: account) }

  describe '#call' do
    context 'when text is blank or too short' do
      it 'returns nil' do
        expect(described_class.call(text: "", account: account)).to be_nil
        expect(described_class.call(text: "abc", account: account)).to be_nil
      end
    end

    context 'when google integration is active' do
      before do
        create(:integration, account: account, provider: :google_translate, status: :active, credentials: { "api_key" => "test_key" })
      end

      it 'uses google translate API for detection' do
        mock_response = instance_double(HTTParty::Response, success?: true, parsed_response: {
          "data" => {
            "detections" => [
              [{ "language" => "es", "confidence" => 0.9, "isReliable" => false }]
            ]
          }
        })
        expect(HTTParty).to receive(:post).with(
          "https://translation.googleapis.com/language/translate/v2/detect",
          body: { q: text, key: "test_key" }.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        ).and_return(mock_response)

        expect(service.call).to eq("es")
      end

      it 'returns nil if confidence is low' do
        mock_response = instance_double(HTTParty::Response, success?: true, parsed_response: {
          "data" => {
            "detections" => [
              [{ "language" => "es", "confidence" => 0.4 }]
            ]
          }
        })
        allow(HTTParty).to receive(:post).and_return(mock_response)
        
        expect(service.call).to be_nil
      end
    end

    context 'when fallback to libre translate' do
      before do
        stub_const("ENV", ENV.to_hash.merge("OS_TRANSLATOR_URL" => "http://10.0.0.13:5000/translate"))
      end

      it 'uses libre translate detect endpoint by parsing URL' do
        mock_response = instance_double(HTTParty::Response, success?: true, parsed_response: [
          { "confidence" => 0.8, "language" => "es" }
        ])
        
        expect(HTTParty).to receive(:post).with(
          "http://10.0.0.13:5000/detect",
          body: { q: text }.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        ).and_return(mock_response)

        expect(service.call).to eq("es")
      end
      
      it 'returns nil if HTTParty request fails' do
        mock_response = instance_double(HTTParty::Response, success?: false, code: 500, body: "Error")
        allow(HTTParty).to receive(:post).and_return(mock_response)
        
        expect(service.call).to be_nil
      end
    end
  end
end

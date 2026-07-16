require 'rails_helper'

RSpec.describe Channels::Whatsapp::SignupService do
  let(:account) { double('Account') }
  let(:service) { described_class.new(code: 'auth_code', account: account) }

  describe '#call' do
    let(:oauth_response) { double('Response', success?: true, body: '{"access_token": "token123"}') }
    let(:api_mock) { instance_double(Koala::Facebook::API) }

    before do
      allow(oauth_response).to receive(:[]).with("access_token").and_return("token123")
      allow(HTTParty).to receive(:get).with(/oauth\/access_token/, anything).and_return(oauth_response)
      allow(Koala::Facebook::API).to receive(:new).with("token123").and_return(api_mock)
    end

    it 'exchanges code and fetches WABAs and phone numbers' do
      wabas = [{ "id" => "waba_1" }]
      phones = [{ "id" => "phone_1", "display_phone_number" => "123456789" }]
      
      allow(api_mock).to receive(:get_connections).with("me", "accounts").and_return([])
      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return(wabas)
      allow(api_mock).to receive(:get_connections).with("waba_1", "phone_numbers").and_return(phones)

      result = service.call

      expect(result).to eq({
        access_token: "token123",
        waba_id: "waba_1",
        phone_number_id: "phone_1",
        display_phone_number: "123456789"
      })
    end

    it 'falls back to HTTParty for wabas and phones if Koala fails' do
      allow(api_mock).to receive(:get_connections).with("me", "accounts").and_return([])
      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_raise(StandardError.new)
      allow(api_mock).to receive(:get_connections).with("waba_2", "phone_numbers").and_raise(StandardError.new)
      allow(api_mock).to receive(:access_token).and_return("token123")

      waba_response = double('Response', parsed_response: { "data" => [{ "id" => "waba_2" }] })
      phone_response = double('Response', parsed_response: { "data" => [{ "id" => "phone_2", "display_phone_number" => "987" }] })
      
      allow(HTTParty).to receive(:get).with(/client_whatsapp_business_accounts/, anything).and_return(waba_response)
      allow(HTTParty).to receive(:get).with(/phone_numbers/, anything).and_return(phone_response)

      result = service.call

      expect(result[:waba_id]).to eq("waba_2")
      expect(result[:phone_number_id]).to eq("phone_2")
    end
  end
end

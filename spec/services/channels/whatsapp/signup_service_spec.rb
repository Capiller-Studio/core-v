# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::SignupService do
  let(:account) { double('Account') }
  let(:service) { described_class.new(code: 'auth_code', account: account) }

  describe '#call' do
    let(:oauth_response) { double('Response', success?: true, body: '{"access_token": "token123"}') }
    let(:subscribed_apps_response) { double('Response', success?: true, body: '{"success": true}') }
    let(:phone_details_response) do
      double('Response', success?: true, parsed_response: { "display_phone_number" => "+1 555-123-4567", "verified_name" => "Techbolic Support" })
    end
    let(:api_mock) { instance_double(Koala::Facebook::API) }

    before do
      allow(oauth_response).to receive(:[]).with("access_token").and_return("token123")
      allow(oauth_response).to receive(:present?).and_return(true)
      allow(HTTParty).to receive(:get).and_return(double('Response', success?: true, parsed_response: { "data" => [] }))
      allow(HTTParty).to receive(:get).with(/oauth\/access_token/, anything).and_return(oauth_response)
      allow(HTTParty).to receive(:post).with(/subscribed_apps/, anything).and_return(subscribed_apps_response)
      allow(HTTParty).to receive(:post).with(/register/, anything).and_return(double('Response', success?: true))
      allow(HTTParty).to receive(:get).with(/phone_1$/, anything).and_return(phone_details_response)
      allow(Koala::Facebook::API).to receive(:new).with("token123").and_return(api_mock)
    end

    it 'exchanges code, subscribes WABA webhooks, and returns channel attributes' do
      wabas = [{ "id" => "waba_1" }]
      phones = [{ "id" => "phone_1", "display_phone_number" => "123456789" }]

      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return(wabas)
      allow(api_mock).to receive(:get_connections).with("waba_1", "phone_numbers", any_args).and_return(phones)
      allow(api_mock).to receive(:access_token).and_return("token123")

      expect(HTTParty).to receive(:post).with(/waba_1\/subscribed_apps/, hash_including(
        headers: hash_including("Authorization" => "Bearer token123")
      )).and_return(subscribed_apps_response)

      result = service.call

      expect(result).to eq({
        access_token: "token123",
        waba_id: "waba_1",
        phone_number_id: "phone_1",
        display_phone_number: "+15551234567",
        name: "Techbolic Support"
      })
    end

    it 'supports Display Name Only signup when display_phone_number is missing from Meta' do
      wabas = [{ "id" => "waba_1" }]
      phones = [{ "id" => "phone_display_only", "verified_name" => "Brand Display Name", "display_phone_number" => nil }]

      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return(wabas)
      allow(api_mock).to receive(:get_connections).with("waba_1", "phone_numbers", any_args).and_return(phones)
      allow(api_mock).to receive(:access_token).and_return("token123")

      display_only_resp = double('Response', success?: true, parsed_response: {
        "id" => "phone_display_only",
        "verified_name" => "Brand Display Name",
        "display_phone_number" => nil
      })
      allow(HTTParty).to receive(:get).with(/phone_display_only$/, anything).and_return(display_only_resp)

      result = service.call

      expect(result[:access_token]).to eq("token123")
      expect(result[:waba_id]).to eq("waba_1")
      expect(result[:phone_number_id]).to eq("phone_display_only")
      expect(result[:display_phone_number]).to eq("Brand Display Name")
      expect(result[:name]).to eq("Brand Display Name")
    end

    it 'uses provided waba_id and phone_number_id when passed from session_info' do
      session_service = described_class.new(
        code: 'auth_code',
        account: account,
        waba_id: 'session_waba_123',
        phone_number_id: 'session_phone_456'
      )

      allow(api_mock).to receive(:access_token).and_return("token123")
      session_phone_response = double('Response', success?: true, parsed_response: { "display_phone_number" => "+44 7700 900077", "verified_name" => "Deskbolic UK" })
      allow(HTTParty).to receive(:get).with(/session_phone_456$/, anything).and_return(session_phone_response)

      expect(HTTParty).to receive(:post).with(/session_waba_123\/subscribed_apps/, anything).and_return(subscribed_apps_response)

      result = session_service.call

      expect(result).to eq({
        access_token: "token123",
        waba_id: "session_waba_123",
        phone_number_id: "session_phone_456",
        display_phone_number: "+447700900077",
        name: "Deskbolic UK"
      })
    end

    it 'raises an error if code exchange fails' do
      failed_oauth = double('Response', success?: false, body: '{"error": {"message": "Invalid verification code format"}}')
      allow(HTTParty).to receive(:get).with(/oauth\/access_token/, anything).and_return(failed_oauth)

      expect { service.call }.to raise_error(RuntimeError, /Failed to exchange code for token/)
    end

    it 'raises an error if no WABAs can be discovered' do
      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return([])
      allow(api_mock).to receive(:access_token).and_return("token123")
      allow(HTTParty).to receive(:get).with(/client_whatsapp_business_accounts/, anything).and_return(double('Response', parsed_response: { "data" => [] }))

      expect { service.call }.to raise_error(RuntimeError, /No WhatsApp Business Accounts found/)
    end

    it 'raises an error if no phone numbers are found in WABA' do
      wabas = [{ "id" => "waba_empty" }]
      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return(wabas)
      allow(api_mock).to receive(:get_connections).with("waba_empty", "phone_numbers", any_args).and_return([])
      allow(api_mock).to receive(:access_token).and_return("token123")
      allow(HTTParty).to receive(:get).with(/waba_empty\/phone_numbers/, anything).and_return(double('Response', parsed_response: { "data" => [] }))

      expect { service.call }.to raise_error(RuntimeError, /No Phone Numbers found/)
    end

    it 'gracefully handles subscribed_apps warning without failing signup' do
      wabas = [{ "id" => "waba_1" }]
      phones = [{ "id" => "phone_1", "display_phone_number" => "123456789" }]

      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return(wabas)
      allow(api_mock).to receive(:get_connections).with("waba_1", "phone_numbers", any_args).and_return(phones)
      allow(api_mock).to receive(:access_token).and_return("token123")

      warning_response = double('Response', success?: false, body: '{"error": "already_subscribed"}')
      allow(HTTParty).to receive(:post).with(/subscribed_apps/, anything).and_return(warning_response)

      expect(Rails.logger).to receive(:warn).with(/subscribed_apps warning/)

      result = service.call
      expect(result[:access_token]).to eq("token123")
      expect(result[:waba_id]).to eq("waba_1")
    end

    it 'falls back to WABA phone list when direct phone metadata lookup fails' do
      wabas = [{ "id" => "waba_1" }]
      phones = [{ "id" => "phone_1", "display_phone_number" => "+1 800-555-0199", "verified_name" => "Fallback Name" }]

      allow(api_mock).to receive(:get_object).with("me/client_whatsapp_business_accounts").and_return(wabas)
      allow(api_mock).to receive(:get_connections).with("waba_1", "phone_numbers", any_args).and_return(phones)
      allow(api_mock).to receive(:access_token).and_return("token123")

      failed_phone_get = double('Response', success?: false, parsed_response: nil)
      allow(HTTParty).to receive(:get).with(/phone_1$/, anything).and_return(failed_phone_get)

      result = service.call
      expect(result[:display_phone_number]).to eq("+18005550199")
      expect(result[:name]).to eq("Fallback Name")
    end

    it 'discovers WABA ID and Phone Number ID from debug_token granular scopes' do
      allow(Rails.application.credentials).to receive(:dig).and_call_original
      allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_id).and_return("app_123")
      allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_secret).and_return("secret_123")

      debug_token_response = double('Response', success?: true, parsed_response: {
        "data" => {
          "granular_scopes" => [
            { "scope" => "whatsapp_business_management", "target_ids" => ["debug_waba_789"] },
            { "scope" => "whatsapp_business_messaging", "target_ids" => ["debug_phone_999"] }
          ]
        }
      })
      allow(HTTParty).to receive(:get).with(/debug_token/, anything).and_return(debug_token_response)
      allow(api_mock).to receive(:access_token).and_return("token123")

      phone_response = double('Response', success?: true, parsed_response: {
        "display_phone_number" => "+1 555-999-0000",
        "verified_name" => "Debug WABA Name"
      })
      allow(HTTParty).to receive(:get).with(/debug_phone_999$/, anything).and_return(phone_response)

      result = service.call
      expect(result[:waba_id]).to eq("debug_waba_789")
      expect(result[:phone_number_id]).to eq("debug_phone_999")
      expect(result[:display_phone_number]).to eq("+15559990000")
      expect(result[:name]).to eq("Debug WABA Name")
    end
  end
end

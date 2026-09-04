# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::TemplateFetcher do
  let(:whatsapp_channel) do
    double(
      'Channel::Whatsapp',
      business_account_id: 'waba_123',
      business_account_endpoint: 'https://graph.facebook.com/v26.0/waba_123',
      api_headers: { 'Authorization' => 'Bearer test_token' }
    )
  end
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  describe '#call' do
    it 'fetches and caches approved templates' do
      api_response = {
        'data' => [
          { 'name' => 'ticket_resolved', 'status' => 'APPROVED', 'language' => 'en_US' },
          { 'name' => 'summer_promo', 'status' => 'REJECTED', 'language' => 'en_US' },
          { 'name' => 'account_alert', 'status' => 'APPROVED', 'language' => 'es' }
        ]
      }
      response = double('Response', success?: true, parsed_response: api_response, code: 200, unauthorized?: false)

      expect(HTTParty).to receive(:get).with(
        'https://graph.facebook.com/v26.0/waba_123/message_templates',
        headers: { 'Authorization' => 'Bearer test_token' },
        query: { limit: 100, fields: 'name,status,category,language,components' }
      ).and_return(response)

      expect(whatsapp_channel).to receive(:update_columns).with(
        hash_including(
          message_templates: [
            { 'name' => 'ticket_resolved', 'status' => 'APPROVED', 'language' => 'en_US' },
            { 'name' => 'account_alert', 'status' => 'APPROVED', 'language' => 'es' }
          ]
        )
      )

      result = service.call
      expect(result.size).to eq(2)
      expect(result.pluck('name')).to contain_exactly('ticket_resolved', 'account_alert')
    end

    it 'handles pagination across multiple pages' do
      page1_response = double('Response', success?: true, code: 200, unauthorized?: false, parsed_response: {
        'data' => [{ 'name' => 'template_page_1', 'status' => 'APPROVED' }],
        'paging' => { 'next' => 'https://graph.facebook.com/v26.0/waba_123/message_templates?after=cursor_1' }
      })

      page2_response = double('Response', success?: true, code: 200, unauthorized?: false, parsed_response: {
        'data' => [{ 'name' => 'template_page_2', 'status' => 'APPROVED' }],
        'paging' => {}
      })

      expect(HTTParty).to receive(:get).with(
        'https://graph.facebook.com/v26.0/waba_123/message_templates',
        headers: { 'Authorization' => 'Bearer test_token' },
        query: { limit: 100, fields: 'name,status,category,language,components' }
      ).and_return(page1_response).ordered

      expect(HTTParty).to receive(:get).with(
        'https://graph.facebook.com/v26.0/waba_123/message_templates?after=cursor_1',
        headers: { 'Authorization' => 'Bearer test_token' },
        query: nil
      ).and_return(page2_response).ordered

      expect(whatsapp_channel).to receive(:update_columns).with(
        hash_including(
          message_templates: [
            { 'name' => 'template_page_1', 'status' => 'APPROVED' },
            { 'name' => 'template_page_2', 'status' => 'APPROVED' }
          ]
        )
      )

      result = service.call
      expect(result.size).to eq(2)
      expect(result.pluck('name')).to eq(['template_page_1', 'template_page_2'])
    end

    it 'triggers authorization_error! when Meta returns 401 Unauthorized' do
      unauthorized_response = double('Response', success?: false, code: 401, unauthorized?: true, parsed_response: { 'error' => { 'message' => 'Invalid OAuth' } })

      expect(HTTParty).to receive(:get).and_return(unauthorized_response)
      expect(whatsapp_channel).to receive(:authorization_error!)
      expect(whatsapp_channel).to receive(:update_columns).with(
        hash_including(message_templates: [])
      )

      result = service.call
      expect(result).to eq([])
    end

    it 'gracefully handles HTTP failures during pagination' do
      page1_response = double('Response', success?: true, code: 200, unauthorized?: false, parsed_response: {
        'data' => [{ 'name' => 'template_1', 'status' => 'APPROVED' }],
        'paging' => { 'next' => 'https://graph.facebook.com/v26.0/waba_123/message_templates?after=cursor_err' }
      })

      page2_error_response = double('Response', success?: false, code: 500, unauthorized?: false, parsed_response: 'Internal Server Error')

      expect(HTTParty).to receive(:get).and_return(page1_response).ordered
      expect(HTTParty).to receive(:get).and_return(page2_error_response).ordered

      expect(whatsapp_channel).to receive(:update_columns).with(
        hash_including(
          message_templates: [{ 'name' => 'template_1', 'status' => 'APPROVED' }]
        )
      )

      result = service.call
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('template_1')
    end

    it 'returns empty array when business_account_id is blank' do
      allow(whatsapp_channel).to receive(:business_account_id).and_return(nil)
      expect(service.call).to eq([])
    end

    it 'rescues and logs unexpected exceptions' do
      expect(HTTParty).to receive(:get).and_raise(StandardError.new("Network failure"))
      expect(Rails.logger).to receive(:error).with(/WhatsApp TemplateFetcher error for waba_123: Network failure/)

      expect(service.call).to eq([])
    end
  end
end

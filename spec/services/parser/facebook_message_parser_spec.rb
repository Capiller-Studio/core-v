require 'rails_helper'

RSpec.describe Parser::FacebookMessageParser do
  let(:raw_response) do
    {
      "messaging" => {
        "sender" => { "id" => "123" },
        "recipient" => { "id" => "456" },
        "timestamp" => 1458692752478,
        "message" => {
          "mid" => "mid.1457764197618:41d102a3e1ae206a38",
          "seq" => 73,
          "text" => "hello, world!",
          "is_echo" => false,
          "reply_to" => { "mid" => "mid.123" },
          "attachments" => [{ "type" => "image", "payload" => { "url" => "http://test.com" } }]
        },
        "delivery" => { "watermark" => 123456 },
        "read" => { "watermark" => 654321 }
      }
    }.to_json
  end

  let(:service) { described_class.new(response: raw_response) }

  describe 'parsing fields' do
    it 'parses message fields' do
      expect(service.sender_id).to eq("123")
      expect(service.recipient_id).to eq("456")
      expect(service.timestamp).to eq(1458692752478)
      expect(service.mid).to eq("mid.1457764197618:41d102a3e1ae206a38")
      expect(service.sequence).to eq(73)
      expect(service.content).to eq("hello, world!")
      expect(service.echo?).to be false
      expect(service.reply_to_mid).to eq("mid.123")
      expect(service.attachments).to be_an(Array)
      expect(service.delivery_watermark).to eq(123456)
      expect(service.read_watermark).to eq(654321)
    end
  end
end

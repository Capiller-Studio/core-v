require 'rails_helper'

RSpec.describe Parser::InstagramMessageParser do
  let(:message_hash) do
    {
      "sender" => { "id" => "123" },
      "recipient" => { "id" => "456" },
      "timestamp" => 1458692752478,
      "message" => {
        "mid" => "mid.1457764197618",
        "seq" => 73,
        "text" => "hello, insta!",
        "is_echo" => false,
        "reply_to" => { "mid" => "mid.123" }
      },
      "delivery" => { "watermark" => 123456 },
      "read" => { "watermark" => 654321 }
    }
  end

  let(:service) { described_class.new(message: message_hash) }

  describe 'parsing fields' do
    it 'parses message fields' do
      expect(service.sender_id).to eq("123")
      expect(service.recipient_id).to eq("456")
      expect(service.timestamp).to eq(1458692752478)
      expect(service.mid).to eq("mid.1457764197618")
      expect(service.sequence).to eq(73)
      expect(service.content).to eq("hello, insta!")
      expect(service.echo?).to be false
      expect(service.reply_to_mid).to eq("mid.123")
      expect(service.attachments).to eq([])
      expect(service.delivery_watermark).to eq(123456)
      expect(service.read_watermark).to eq(654321)
    end
  end
end

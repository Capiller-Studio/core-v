require 'rails_helper'

RSpec.describe Parser::MailParser do
  let(:mail) do
    double('Mail',
      subject: 'Test Subject',
      from: ['sender@example.com'],
      reply_to: ['reply@example.com'],
      to: ['receiver@example.com'],
      cc: [],
      bcc: [],
      message_id: 'msg-123',
      in_reply_to: 'msg-abc',
      references: ['msg-xyz'],
      content_type: 'text/html',
      html_part: nil,
      text_part: nil,
      parts: [],
      decoded: '<h1>Hello</h1>',
      attachments: []
    )
  end

  let(:service) { described_class.new(mail: mail) }

  before do
    allow(mail).to receive(:[]).with(:reply_to).and_return(double(value: 'reply@example.com'))
    allow(mail).to receive(:[]).with(:from).and_return(double(value: 'sender@example.com'))
    allow(mail).to receive(:[]).with('X-Original-Sender').and_return(nil)
    allow(mail).to receive(:[]).with('X-Forwarded-For').and_return(nil)
    allow(mail).to receive(:[]).with('X-Original-To').and_return(nil)
    allow(mail).to receive(:[]).with('Auto-Submitted').and_return(nil)
    allow(mail).to receive(:[]).with('X-Autoreply').and_return(nil)
    allow(mail).to receive(:[]).with('X-Auto-Response-Suppress').and_return(nil)
    allow(mail).to receive(:[]).with('X-PM-Message-Id').and_return(nil)
    allow(mail).to receive(:[]).with('X-Mailer-Daemon').and_return(nil)
    allow(mail).to receive(:[]).with('Precedence').and_return(nil)
    allow(mail).to receive(:[]).with('Feedback-ID').and_return(nil)
  end

  describe 'parsing fields' do
    it 'parses subject and addresses' do
      expect(service.subject).to eq('Test Subject')
      expect(service.from).to include('sender@example.com', 'reply@example.com')
      expect(service.original_sender).to eq('reply@example.com')
      expect(service.receiver).to include('receiver@example.com')
    end

    it 'detects if message is a reply' do
      expect(service.reply?).to be true
    end

    it 'extracts html content and sanitizes it' do
      expect(service.html_content).to eq('<h1>Hello</h1>')
      expect(service.html_content_parsed).to eq('<h1>Hello</h1>')
    end

    it 'handles auto-reply logic' do
      expect(service.auto_reply?).to be false
      allow(mail).to receive(:[]).with('Auto-Submitted').and_return(double(value: 'auto-replied'))
      # resetting memoized value by re-instantiating
      expect(described_class.new(mail: mail).auto_reply?).to be true
    end

    it 'extracts reply_to_conversation_uuid' do
      allow(mail).to receive(:to).and_return(['reply+uuid123@example.com'])
      expect(service.reply_to_conversation_uuid).to eq('uuid123')
    end
  end
end

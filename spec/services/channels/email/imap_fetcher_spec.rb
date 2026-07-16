require 'rails_helper'

RSpec.describe Channels::Email::ImapFetcher do
  let(:account) { double('Account') }
  let(:email_channel) do
    double('Channel::Email', 
      id: 1, 
      imap_enabled?: true, 
      imap_config: { address: 'imap.example.com', port: 993, enable_ssl: true, username: 'user', password: 'pwd' },
      account: account
    )
  end
  let(:service) { described_class.new(email_channel: email_channel) }

  describe '#call' do
    let(:imap_client) { double('Net::IMAP') }

    before do
      allow(Net::IMAP).to receive(:new).with('imap.example.com', port: 993, ssl: true).and_return(imap_client)
      allow(imap_client).to receive(:login).with('user', 'pwd')
      
      allow(imap_client).to receive(:logout)
      allow(imap_client).to receive(:disconnect)
    end

    context 'when imap is not enabled' do
      before do
        allow(email_channel).to receive(:imap_enabled?).and_return(false)
      end

      it 'returns early' do
        expect(Net::IMAP).not_to receive(:new)
        service.call
      end
    end

    context 'when processing emails successfully' do
      let(:msg_id) { 123 }
      let(:raw_email) { 'raw email content' }
      let(:fetch_data) { double('FetchData', attr: { 'RFC822' => raw_email }) }
      let(:mail_mock) { double('Mail', message_id: 'msg-abc') }

      before do
        allow(imap_client).to receive(:select).with('INBOX')
        allow(imap_client).to receive(:search).with(['UNSEEN']).and_return([msg_id])
        allow(imap_client).to receive(:fetch).with(msg_id, 'RFC822').and_return([fetch_data])
        
        allow(Mail).to receive(:new).with(raw_email).and_return(mail_mock)

        stub_const('Mailboxes::ConversationCreator', double('ConversationCreator'))
        allow(account).to receive_message_chain(:messages, :exists?).with(external_id: 'msg-abc').and_return(false)
      end

      it 'fetches, processes, and marks as seen' do
        expect(Mailboxes::ConversationCreator).to receive(:call).with(mail: mail_mock, email_channel: email_channel)
        expect(imap_client).to receive(:store).with(msg_id, '+FLAGS', [:Seen])

        service.call
      end

      context 'when message was already processed' do
        before do
          allow(account).to receive_message_chain(:messages, :exists?).with(external_id: 'msg-abc').and_return(true)
        end

        it 'skips processing' do
          expect(Mailboxes::ConversationCreator).not_to receive(:call)
          expect(imap_client).not_to receive(:store)

          service.call
        end
      end
    end

    context 'when connection fails' do
      before do
        allow(Net::IMAP).to receive(:new).and_raise(SocketError.new('Connection refused'))
      end

      it 'logs error and does not blow up' do
        expect(Rails.logger).to receive(:error).with(/IMAP connection failed/)
        expect { service.call }.not_to raise_error
      end
    end
  end
end

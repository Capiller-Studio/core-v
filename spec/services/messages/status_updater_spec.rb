require 'rails_helper'

RSpec.describe Messages::StatusUpdater do
  let(:account) { create(:account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'when updating by external_ids' do
      let!(:message1) { create(:message, account: account, external_id: 'ext1', status: :sent) }
      let!(:message2) { create(:message, account: account, external_id: 'ext2', status: :sent) }
      let!(:message3) { create(:message, account: account, external_id: 'ext3', status: :sent) }
      
      let(:service) { described_class.new(account_id: account.id, status: :delivered, params: { external_ids: ['ext1', 'ext2'] }) }

      it 'updates status of messages matching external_ids' do
        service.call
        
        expect(message1.reload.status).to eq('delivered')
        expect(message2.reload.status).to eq('delivered')
        expect(message3.reload.status).to eq('sent')
      end
    end

    context 'when updating by watermark' do
      let(:customer) { create(:customer, account: account, external_id: 'cust1') }
      let(:conversation) { create(:conversation, account: account) }
      
      before do
        conversation.conversation_members.create!(member: customer, account: account)
      end
      
      let!(:old_message) { create(:message, account: account, conversation: conversation, status: :sent, created_at: 2.minutes.ago) }
      let!(:new_message) { create(:message, account: account, conversation: conversation, status: :sent, created_at: Time.current) }
      
      let(:watermark) { 1.minute.ago.to_i * 1000 } # watermark in milliseconds
      
      let(:service) do
        described_class.new(
          account_id: account.id,
          status: :read,
          params: { watermark: watermark, customer_external_id: 'cust1' }
        )
      end

      it 'updates status of messages older than watermark' do
        service.call
        
        expect(old_message.reload.status).to eq('read')
        expect(new_message.reload.status).to eq('sent')
      end
    end
  end
end

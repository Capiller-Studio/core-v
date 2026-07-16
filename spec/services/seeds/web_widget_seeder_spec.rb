require 'rails_helper'

RSpec.xdescribe Seeds::WebWidgetSeeder do
  describe '#seed' do
    it 'runs without errors and creates web widget data' do
      Searchkick.callbacks(false) do
        expect {
          described_class.seed
        }.not_to raise_error
        
        # Verify that it created the expected records
        account = Account.first
        expect(account).not_to be_nil
        
        widget = Channel::WebWidget.find_by(account: account, name: 'Demo Widget')
        expect(widget).not_to be_nil
        
        inbox = Inbox.find_by(account: account, name: 'Web Widget Inbox')
        expect(inbox).not_to be_nil
        expect(inbox.channel).to eq(widget)
        
        # Check portal
        account.with_shard do
          portal = HelpCenter::Portal.find_by(account: account, name: 'Demo Portal')
          expect(portal).not_to be_nil
          expect(widget.portal).to eq(portal)
        end
        
        # Verify agents
        agents = User.where('email LIKE ?', 'agent%@deskbolic.test')
        expect(agents.count).to eq(2)
        
        # Verify customer
        customer = Customer.find_by(email: 'customer@example.com')
        expect(customer).not_to be_nil
        
        # Verify conversation
        conv = account.conversations.find_by(identifier: 'seed-web-widget-conv-001')
        expect(conv).not_to be_nil
        expect(conv.messages.count).to eq(2)
      end
    end
  end
end

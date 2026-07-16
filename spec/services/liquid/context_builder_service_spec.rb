require 'rails_helper'

RSpec.describe Liquid::ContextBuilderService do
  let(:customer) { double('Customer', name: 'John Doe', email: 'john@example.com', full_phone_number: '+1234567890') }
  let(:inbox) { double('Inbox', name: 'Support') }
  let(:account) { double('Account', name: 'Acme Corp') }
  let(:message) { double('Message', content: 'Hello there!') }
  
  let(:conversation) do
    double('Conversation', 
      customers: [customer], 
      identifier: 'CONV-123', 
      inbox: inbox, 
      account: account,
      title: 'Help issue'
    )
  end

  let(:agent) { double('User', display_name: 'Agent Smith', email: 'agent@example.com') }
  let(:event) { double('Event', title: 'New Event', description: 'Event details') }

  describe '#call' do
    context 'without template type filter' do
      let(:service) { described_class.new(conversation: conversation, agent: agent, message: message, event: event) }

      it 'builds full variables' do
        result = service.call

        expect(result['agent']['name']).to eq('Agent Smith')
        expect(result['customer']['name']).to eq('John Doe')
        expect(result['conversation']['subject']).to eq('Help issue')
        expect(result['inbox']['name']).to eq('Support')
        expect(result['account']['name']).to eq('Acme Corp')
        expect(result['message']['content']).to eq('Hello there!')
        expect(result['event']['title']).to eq('New Event')
      end

      it 'determines original_subject from first message if title is missing' do
        allow(conversation).to receive(:title).and_return(nil)
        first_message = double('Message', content: 'First message content')
        messages_scope = double('MessagesScope')
        
        allow(conversation).to receive(:messages).and_return(messages_scope)
        allow(messages_scope).to receive(:order).with(created_at: :asc).and_return([first_message])
        
        result = service.call
        expect(result['conversation']['subject']).to eq('First message content')
      end
    end

    context 'with canned_response template type' do
      let(:service) { described_class.new(conversation: conversation, agent: agent, template_type: 'canned_response') }

      before do
        stub_const('CannedResponse::TEMPLATE_VARIABLES', {
          "agent" => ["name"],
          "customer" => ["name", "email"]
        })
      end

      it 'filters variables based on allowed keys' do
        result = service.call
        
        expect(result.keys).to contain_exactly('agent', 'customer')
        expect(result['agent'].keys).to contain_exactly('name')
        expect(result['customer'].keys).to contain_exactly('name', 'email')
      end
    end

    context 'with email template type' do
      let(:service) { described_class.new(conversation: conversation, agent: agent, template_type: 'custom_email') }

      before do
        stub_const('EmailTemplate::TEMPLATE_VARIABLES', {
          "custom_email" => {
            "conversation" => [] # empty array means all sub-keys allowed
          }
        })
      end

      it 'allows all subkeys if array is empty' do
        result = service.call
        
        expect(result.keys).to contain_exactly('conversation')
        expect(result['conversation']).to include('subject' => 'Help issue', 'identifier' => 'CONV-123')
      end
    end
  end
end

require 'rails_helper'

RSpec.xdescribe Search::SearchService, search: true do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assignee) { create(:user) }
  let(:team) { create(:team, account: account) }

  let!(:conversation1) do
    create(:conversation,
           account: account,
           inbox: inbox,
           assignee: assignee,
           team: team,
           status: 'active',
           priority: 'high',
           created_at: 2.days.ago)
  end

  let!(:conversation2) do
    create(:conversation,
           account: account,
           inbox: inbox,
           status: 'resolved',
           created_at: 10.days.ago)
  end

  let!(:message1) do
    create(:message,
           conversation: conversation1,
           account: account,
           inbox: inbox,
           content: 'Hello, this is a test message regarding billing.',
           content_type: 'text',
           visibility: 'global',
           created_at: 1.day.ago)
  end

  let!(:message2) do
    create(:message,
           conversation: conversation2,
           account: account,
           inbox: inbox,
           content: 'The quick brown fox jumps over the lazy dog.',
           content_type: 'text',
           visibility: 'global',
           created_at: 9.days.ago)
  end

  let!(:internal_note) do
    create(:message,
           conversation: conversation1,
           account: account,
           inbox: inbox,
           content: 'This is an internal note about billing.',
           content_type: 'text',
           visibility: 'personal') # Should not be searchable
  end

  before do
    # Force sync reindexing for the tests
    Conversation.reindex
    Message.reindex
    Conversation.search_index.refresh
    Message.search_index.refresh
  end

  describe '#call' do
    context 'when query is blank' do
      it 'returns empty results' do
        service = described_class.new(query: '', account_id: account.id)
        result = service.call

        expect(result[:conversations]).to be_empty
        expect(result[:messages]).to be_empty
      end
    end

    context 'when searching conversations' do
      it 'filters by account_id' do
        other_account = create(:account)
        service = described_class.new(query: conversation1.identifier, account_id: other_account.id)
        
        expect(service.call[:conversations]).to be_empty
      end

      it 'returns matching conversations and respects type filter' do
        service = described_class.new(query: conversation1.identifier, account_id: account.id, type: 'conversations')
        result = service.call

        expect(result[:conversations]).to include(conversation1)
        expect(result[:messages]).to be_empty
      end

      it 'applies status filter' do
        service = described_class.new(query: conversation1.identifier, account_id: account.id, filters: { status: 'resolved' })
        expect(service.call[:conversations]).to be_empty

        service_resolved = described_class.new(query: conversation2.identifier, account_id: account.id, filters: { status: 'resolved' })
        expect(service_resolved.call[:conversations]).to include(conversation2)
      end

      it 'applies assignee and team filters' do
        service = described_class.new(
          query: conversation1.identifier, 
          account_id: account.id, 
          filters: { assignee_id: assignee.id, team_id: team.id }
        )
        expect(service.call[:conversations]).to include(conversation1)
      end

      it 'applies date range filters' do
        service = described_class.new(
          query: conversation1.identifier, 
          account_id: account.id, 
          filters: { date_from: 3.days.ago, date_to: 1.day.ago }
        )
        expect(service.call[:conversations]).to include(conversation1)
        expect(service.call[:conversations]).not_to include(conversation2)
      end
    end

    context 'when searching messages' do
      it 'returns matching global text messages' do
        service = described_class.new(query: 'billing', account_id: account.id, type: 'messages')
        result = service.call

        expect(result[:messages]).to include(message1)
        expect(result[:conversations]).to be_empty
      end

      it 'does not return personal notes' do
        service = described_class.new(query: 'internal', account_id: account.id)
        expect(service.call[:messages]).to be_empty
      end

      it 'includes highlight tags in the response' do
        service = described_class.new(query: 'billing', account_id: account.id)
        result = service.call
        
        # Searchkick provides highlights via the hit object
        first_message = result[:messages].first
        expect(first_message.search_highlights).to have_key(:content)
        expect(first_message.search_highlights[:content]).to match(/<mark>billing<\/mark>/i)
      end
    end

    context 'when searchkick raises an error' do
      before do
        allow(Conversation).to receive(:search).and_raise(Searchkick::Error.new('Connection failed'))
        allow(Message).to receive(:search).and_raise(Searchkick::Error.new('Connection failed'))
      end

      it 'rescues the error and returns empty arrays' do
        service = described_class.new(query: 'billing', account_id: account.id)
        result = service.call

        expect(result[:conversations]).to be_empty
        expect(result[:messages]).to be_empty
      end
    end
  end

  describe '#suggestions' do
    it 'returns limited results' do
      service = described_class.new(query: 'billing', account_id: account.id)
      result = service.suggestions
      
      expect(result).to have_key(:conversations)
      expect(result).to have_key(:messages)
    end
  end
end

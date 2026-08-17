# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::SearchService do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:team) { create(:team, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account, inbox: inbox) }

  describe '#call' do
    context 'when query is blank' do
      it 'returns empty results without calling search' do
        service = described_class.new(query: '', account_id: account.id)
        result = service.call

        expect(result[:conversations]).to eq([])
        expect(result[:messages]).to eq([])
      end
    end

    context 'when searching conversations' do
      it 'passes query, account_id, and filter options to Conversation.search' do
        expect(Conversation).to receive(:search).with(
          'billing',
          hash_including(
            where: hash_including(account_id: account.id, status: 'open', assignee_id: user.id),
            fields: Search::SearchService::CONVERSATION_FIELDS,
            match: :word_start
          )
        ).and_return([conversation])

        expect(Message).to receive(:search).and_return([])

        service = described_class.new(
          query: 'billing',
          account_id: account.id,
          filters: { status: 'open', assignee_id: user.id }
        )
        result = service.call

        expect(result[:conversations]).to eq([conversation])
      end

      it 'supports filtering by date range' do
        from_date = 7.days.ago
        to_date = Time.current

        expect(Conversation).to receive(:search).with(
          'invoice',
          hash_including(
            where: hash_including(
              account_id: account.id,
              created_at: { gte: from_date, lte: to_date }
            )
          )
        ).and_return([conversation])

        expect(Message).to receive(:search).and_return([])

        service = described_class.new(
          query: 'invoice',
          account_id: account.id,
          filters: { date_from: from_date, date_to: to_date }
        )
        service.call
      end

      it 'skips conversation search when type is messages' do
        expect(Conversation).not_to receive(:search)
        expect(Message).to receive(:search).and_return([message])

        service = described_class.new(query: 'payment', account_id: account.id, type: 'messages')
        result = service.call

        expect(result[:conversations]).to eq([])
        expect(result[:messages]).to eq([message])
      end
    end

    context 'when searching messages' do
      it 'passes query, account_id, global text filters, and highlights to Message.search' do
        expect(Conversation).to receive(:search).and_return([])
        expect(Message).to receive(:search).with(
          'refund',
          hash_including(
            where: hash_including(
              account_id: account.id,
              content_type: 'text',
              visibility: 'global'
            ),
            fields: Search::SearchService::MESSAGE_FIELDS,
            highlight: { tag: '<mark>', fields: { content: {} } }
          )
        ).and_return([message])

        service = described_class.new(query: 'refund', account_id: account.id)
        result = service.call

        expect(result[:messages]).to eq([message])
      end

      it 'skips message search when type is conversations' do
        expect(Conversation).to receive(:search).and_return([conversation])
        expect(Message).not_to receive(:search)

        service = described_class.new(query: 'support', account_id: account.id, type: 'conversations')
        result = service.call

        expect(result[:conversations]).to eq([conversation])
        expect(result[:messages]).to eq([])
      end
    end

    context 'when search encounters an error' do
      it 'rescues Searchkick::Error and returns empty arrays' do
        allow(Conversation).to receive(:search).and_raise(Searchkick::Error.new('Connection failed'))
        allow(Message).to receive(:search).and_raise(Searchkick::Error.new('Connection failed'))

        service = described_class.new(query: 'error_trigger', account_id: account.id)
        result = service.call

        expect(result[:conversations]).to eq([])
        expect(result[:messages]).to eq([])
      end
    end
  end

  describe '#suggestions' do
    it 'passes limit 5 to both conversation and message search' do
      expect(Conversation).to receive(:search).with(
        'quick',
        hash_including(limit: 5)
      ).and_return([conversation])

      expect(Message).to receive(:search).with(
        'quick',
        hash_including(limit: 5)
      ).and_return([message])

      service = described_class.new(query: 'quick', account_id: account.id)
      result = service.suggestions

      expect(result[:conversations]).to eq([conversation])
      expect(result[:messages]).to eq([message])
    end

    it 'returns empty suggestions when query is blank' do
      service = described_class.new(query: '', account_id: account.id)
      result = service.suggestions

      expect(result[:conversations]).to eq([])
      expect(result[:messages]).to eq([])
    end
  end
end

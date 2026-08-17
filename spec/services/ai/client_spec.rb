# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::Client do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:openai_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    allow(Ai::CreditManager).to receive(:call).and_return(true)
    allow(Ai::CreditManager).to receive(:refund!)
  end

  describe '#call' do
    it 'deducts credits, calls OpenAI, and returns response content' do
      expect(openai_client).to receive(:chat).with(
        parameters: hash_including(
          model: 'gpt-5.6-luna',
          messages: [{ role: 'user', content: 'Hello' }]
        )
      ).and_return({
        'choices' => [
          { 'message' => { 'content' => 'Hello! How can I assist you today?' } }
        ]
      })

      result = described_class.call(
        account: account,
        user: user,
        action_type: 'test_action',
        model: :lite,
        messages: [{ role: 'user', content: 'Hello' }]
      )

      expect(result).to eq('Hello! How can I assist you today?')
      expect(Ai::CreditManager).to have_received(:call).with(
        account: account,
        action_type: 'test_action',
        model_used: 'gpt-5.6-luna',
        user: user,
        cost: 1
      )
    end

    it 'refunds credit and re-raises when OpenAI fails' do
      expect(openai_client).to receive(:chat).and_raise(StandardError.new('OpenAI Timeout'))

      expect {
        described_class.call(
          account: account,
          user: user,
          action_type: 'test_action',
          model: :lite,
          messages: [{ role: 'user', content: 'Hello' }]
        )
      }.to raise_error(StandardError, 'OpenAI Timeout')

      expect(Ai::CreditManager).to have_received(:refund!).with(
        account: account,
        amount: 1,
        action_type: 'test_action'
      )
    end

    it 'does not refund when credit deduction itself fails with AiInsufficientBalanceError' do
      allow(Ai::CreditManager).to receive(:call).and_raise(AiInsufficientBalanceError.new('Out of credits'))

      expect {
        described_class.call(
          account: account,
          user: user,
          action_type: 'test_action',
          model: :lite,
          messages: [{ role: 'user', content: 'Hello' }]
        )
      }.to raise_error(AiInsufficientBalanceError)

      expect(openai_client).not_to receive(:chat)
      expect(Ai::CreditManager).not_to have_received(:refund!)
    end
  end
end

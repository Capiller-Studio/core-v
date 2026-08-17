# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::ToneRewriter do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  before do
    allow(Ai::Client).to receive(:call).and_return('Please let us know if you need further help.')
  end

  describe '#call' do
    it 'returns original text when requested tone is invalid' do
      result = described_class.call(
        text: 'Hello world',
        tone: 'aggressive',
        account: account,
        user: user
      )

      expect(result).to eq('Hello world')
      expect(Ai::Client).not_to have_received(:call)
    end

    it 'calls Ai::Client to rewrite text when tone is valid' do
      result = described_class.call(
        text: 'Fix your bug now',
        tone: 'friendly',
        account: account,
        user: user
      )

      expect(result).to eq('Please let us know if you need further help.')
      expect(Ai::Client).to have_received(:call).with(
        hash_including(
          account: account,
          user: user,
          action_type: 'tone_rewrite',
          model: :lite,
          messages: [{ role: 'user', content: 'Fix your bug now' }]
        )
      )
    end
  end
end

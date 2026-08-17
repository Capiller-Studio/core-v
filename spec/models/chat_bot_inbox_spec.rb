# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatBotInbox do
  it 'is defined and inherits from ShardRecord' do
    expect(described_class.superclass).to eq(ShardRecord)
    expect(described_class.defined_enums.keys).to include('status')
  end
end

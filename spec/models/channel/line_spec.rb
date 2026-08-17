# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Line do
  it 'is defined and includes Channelable and Routable' do
    expect(described_class.superclass).to eq(ShardRecord)
    expect(described_class.included_modules).to include(Channelable, Routable)
    expect(described_class.defined_enums.keys).to include('status')
  end
end

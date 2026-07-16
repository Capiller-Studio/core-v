require 'rails_helper'

RSpec.describe Channels::ShortMessage::Signalwire::MessageCreator do
  it 'inherits from Twilio::MessageCreator' do
    expect(described_class.superclass).to eq(Channels::ShortMessage::Twilio::MessageCreator)
  end
end

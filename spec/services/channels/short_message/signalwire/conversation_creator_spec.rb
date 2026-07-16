require 'rails_helper'

RSpec.describe Channels::ShortMessage::Signalwire::ConversationCreator do
  it 'inherits from Twilio::ConversationCreator' do
    expect(described_class.superclass).to eq(Channels::ShortMessage::Twilio::ConversationCreator)
  end
end

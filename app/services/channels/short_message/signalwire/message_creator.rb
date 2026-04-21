# frozen_string_literal: true

module Channels
  module ShortMessage
    module Signalwire
      class MessageCreator < Channels::ShortMessage::Twilio::MessageCreator
        # Identical payload mapping inherited directly from Twilios architecture 
      end
    end
  end
end

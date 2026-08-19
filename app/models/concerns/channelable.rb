# frozen_string_literal: true

module Channelable
  extend ActiveSupport::Concern
  include UsageTrackable

  included do
    tracks_usage :channels
  end

  def supported_formatting
    [] # Default to plain text, restrict formatting completely
  end
end

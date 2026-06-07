# frozen_string_literal: true

module Deskbolic
  module Errors
    class BaseError < StandardError; end

    # Raised when an account attempts to use a feature they don't have access to
    class FeatureNotEnabled < BaseError
      attr_reader :feature

      def initialize(feature, msg = "Feature not enabled for this account")
        @feature = feature
        super(msg)
      end
    end

    # Raised when an account hits a numeric limit
    class LimitReached < BaseError
      attr_reader :limit

      def initialize(limit, msg = "Usage limit reached for this account")
        @limit = limit
        super(msg)
      end
    end
  end
end

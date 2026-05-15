# frozen_string_literal: true

module UnreadTrackable
  extend ActiveSupport::Concern

  included do
    after_create_commit :increment_unread_counts
    after_destroy_commit :decrement_unread_counts
  end

  private

  def increment_unread_counts
    UnreadCounts::Increment.call(self)
  end

  def decrement_unread_counts
    # For mentions, we only decrement if it's unread
    if is_a?(Mention)
      return if read_at.present?
    end

    UnreadCounts::Decrement.call(self)
  end
end

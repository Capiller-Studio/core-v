# frozen_string_literal: true

module Channelable
  extend ActiveSupport::Concern

  included do
    after_create_commit :increment_channel_usage
    after_destroy_commit :decrement_channel_usage
  end

  private

  def increment_channel_usage
    account.increment_usage!(:channels) if account.present?
  end

  def decrement_channel_usage
    account.decrement_usage!(:channels) if account.present?
  end
end

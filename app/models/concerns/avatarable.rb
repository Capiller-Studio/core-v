# frozen_string_literal: true

module Avatarable
  extend ActiveSupport::Concern

  included do
    has_one_attached :avatar do |attachable|
      attachable.variant(:thumb, resize_to_fill: [ 256, 256 ], preprocessed: true)
      attachable.variant(:medium, resize_to_limit: [ 1024, 1024 ])
    end

    validates :avatar, content_type: /\Aimage\/.*\z/, size: { less_than: 5.megabytes }
  end
end

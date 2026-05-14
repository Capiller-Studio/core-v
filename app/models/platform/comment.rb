# frozen_string_literal: true

module Platform
  class Comment < ApplicationRecord
    belongs_to :staff, class_name: "Platform::Staff"
    belongs_to :commentable, polymorphic: true

    validates :content, presence: true
  end
end

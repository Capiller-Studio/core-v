# == Schema Information
#
# Table name: platform_comments
#
#  id               :uuid             not null, primary key
#  content          :text             not null
#  staff_id         :uuid             not null
#  commentable_type :string           not null
#  commentable_id   :uuid             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_platform_comments_on_commentable  (commentable_type,commentable_id)
#  index_platform_comments_on_staff_id     (staff_id)
#

# frozen_string_literal: true

module Platform
  class Comment < ApplicationRecord
    belongs_to :staff, class_name: "Platform::Staff"
    belongs_to :commentable, polymorphic: true

    validates :content, presence: true
  end
end

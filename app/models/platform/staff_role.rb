# frozen_string_literal: true

module Platform
  class StaffRole < ApplicationRecord
    belongs_to :staff, class_name: "Platform::Staff"
    belongs_to :role,  class_name: "Platform::Role"

    validates :staff_id, uniqueness: { scope: :role_id }
  end
end

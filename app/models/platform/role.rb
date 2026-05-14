# frozen_string_literal: true

module Platform
  class Role < ApplicationRecord
    has_many :staff_roles, class_name: "Platform::StaffRole", dependent: :destroy
    has_many :staffs, through: :staff_roles

    validates :name, presence: true
    validates :identifier, presence: true, uniqueness: true

    def permissions_count
      permissions.keys.size
    end
  end
end

# frozen_string_literal: true

module Platform
  class Staff < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :timeoutable and :omniauthable
    devise :database_authenticatable, :recoverable, 
           :rememberable, :validatable, :trackable, :lockable

    has_many :staff_roles, class_name: "Platform::StaffRole", dependent: :destroy
    has_many :roles, through: :staff_roles

    has_many :comments, class_name: "Platform::Comment", dependent: :nullify

    enum :status, { active: 0, suspended: 1, deactivated: 2 }

    validates :name, presence: true

    def super_admin?
      roles.exists?(identifier: "super_admin")
    end

    def can?(resource, action)
      Platform::PermissionService.can?(self, resource, action)
    end
  end
end

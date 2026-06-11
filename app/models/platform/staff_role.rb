# == Schema Information
#
# Table name: platform_staff_roles
#
#  id         :uuid             not null, primary key
#  staff_id   :uuid             not null
#  role_id    :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_platform_staff_roles_on_role_id               (role_id)
#  index_platform_staff_roles_on_staff_id              (staff_id)
#  index_platform_staff_roles_on_staff_id_and_role_id  (staff_id,role_id) UNIQUE
#

# frozen_string_literal: true

module Platform
  class StaffRole < ApplicationRecord
    belongs_to :staff, class_name: "Platform::Staff"
    belongs_to :role,  class_name: "Platform::Role"

    validates :staff_id, uniqueness: { scope: :role_id }
  end
end

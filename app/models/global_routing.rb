# frozen_string_literal: true

# == Schema Information
#
# Table name: global_routings
#
#  id             :uuid             not null, primary key
#  identity_type  :string           not null
#  identity_value :string           not null
#  shard_key      :string           not null
#  account_id     :uuid             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_global_routings_on_account_id                 (account_id)
#  index_global_routings_on_identity_type_and_value    (identity_type,identity_value) UNIQUE
#

class GlobalRouting < ApplicationRecord
  validates :route_type, presence: true
  validates :route_value, presence: true
  validates :shard_key, presence: true
  validates :account_id, presence: true

  # Ensure the route is unique across the entire platform
  validates :route_value, uniqueness: { scope: :route_type }

  belongs_to :account

  def self.find_account_for(route_type, route_value)
    find_by(route_type: route_type, route_value: route_value)
  end
end

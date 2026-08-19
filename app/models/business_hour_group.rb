# frozen_string_literal: true

# == Schema Information
#
# Table name: business_hour_groups
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  description    :text
#  name           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#
# Indexes
#
#  index_business_hour_groups_on_account_id                 (account_id)
#  index_business_hour_groups_on_account_id_and_created_at  (account_id,created_at)
#  index_business_hour_groups_on_account_id_and_name        (account_id,name)
#
class BusinessHourGroup < ShardRecord
  include UsageTrackable

  belongs_to :account

  has_many :business_hours, dependent: :destroy
  has_many :assignment_policies, dependent: :nullify

  validates :name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  accepts_nested_attributes_for :business_hours, allow_destroy: true

  tracks_usage :business_hour_groups
end

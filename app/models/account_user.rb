# frozen_string_literal: true

# == Schema Information
#
# Table name: account_users
#
#  id                      :uuid             not null, primary key
#  availability            :integer          default("offline"), not null
#  availability_changed_at :datetime
#  last_activity_at        :datetime
#  role                    :integer          default("agent"), not null
#  status                  :integer          default("active"), not null
#  status_changed_at       :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :uuid             not null
#  invited_by_id           :uuid
#  user_id                 :uuid             not null
#
# Indexes
#
#  index_account_users_on_account_id              (account_id)
#  index_account_users_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#  index_account_users_on_availability            (availability)
#  index_account_users_on_created_at              (created_at)
#  index_account_users_on_invited_by_id           (invited_by_id)
#  index_account_users_on_role                    (role)
#  index_account_users_on_status                  (status)
#  index_account_users_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (invited_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class AccountUser < ApplicationRecord
  include AccessControl
  include UsageTrackable
  include Trackable

  belongs_to :account
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true

  enum :availability, { online: 0, offline: 1 }
  enum :status, { active: 0, pending_deletion: 1, deleted: 2 }

  tracks_usage :users
  after_create_commit :track_agent_count

  # --- Owner Protections ---
  validate :owner_immutable, on: :update
  validate :single_owner_per_account, on: :create
  before_destroy :prevent_owner_deletion

  private

  def track_agent_count
    account&.track_agent_count!
  end

  # Owner status cannot be removed once assigned
  def owner_immutable
    return unless owner_changed? && owner_was == true

    errors.add(:owner, "cannot be removed from the account owner")
  end

  # Only one owner per account
  def single_owner_per_account
    return unless owner?

    if AccountUser.where(account_id: account_id, owner: true).exists?
      errors.add(:owner, "an owner already exists for this account")
    end
  end

  # Owner cannot be removed from the account
  def prevent_owner_deletion
    return unless owner?

    errors.add(:base, "Account owner cannot be removed")
    throw(:abort)
  end

  after_destroy :cleanup_shard_records
  after_update :cleanup_shard_records_if_deleted

  def cleanup_shard_records_if_deleted
    cleanup_shard_records if saved_change_to_status? && deleted?
  end

  def cleanup_shard_records
    return unless account.present?

    account.with_shard do
      team_ids = account.teams.pluck(:id)
      TeamUser.where(team_id: team_ids, user_id: user_id).destroy_all if team_ids.any?

      inbox_ids = account.inboxes.pluck(:id)
      InboxUser.where(inbox_id: inbox_ids, user_id: user_id).destroy_all if inbox_ids.any?

      Conversation.where(account_id: account.id, assignee_id: user_id).update_all(assignee_id: nil)
    end
  rescue StandardError => e
    Rails.logger.error("Failed to cleanup shard records for AccountUser #{id}: #{e.message}")
  end
end

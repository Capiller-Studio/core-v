# frozen_string_literal: true

module Inbox::Collaborators
  extend ActiveSupport::Concern

  included do
    has_many :inbox_users, dependent: :destroy
    has_many :users, through: :inbox_users, disable_joins: true
    has_many :inbox_teams, dependent: :destroy
    has_many :teams, through: :inbox_teams

    after_save :sync_pending_assignments

    scope :for_user, ->(user) {
      return none unless user

      user_id = user.id.to_s
      user_team_ids = TeamUser.where(user_id: user_id).pluck(:team_id)

      direct_inbox_ids = InboxUser.where(user_id: user_id).select(:inbox_id)
      if user_team_ids.any?
        team_inbox_ids = InboxTeam.where(team_id: user_team_ids).select(:inbox_id)
        where(id: direct_inbox_ids).or(where(id: team_inbox_ids))
      else
        where(id: direct_inbox_ids)
      end
    }

    scope :current_inboxes, ->(current_user) { for_user(current_user) }
  end

  # --- Assignment Methods ---

  def assign_users(user_ids)
    new_user_ids = Array(user_ids).map(&:to_s).reject(&:blank?).uniq
    current_ids = inbox_users.pluck(:user_id).map(&:to_s)

    to_remove = current_ids - new_user_ids
    to_add = new_user_ids - current_ids

    inbox_users.where(user_id: to_remove).destroy_all if to_remove.any?
    to_add.each do |uid|
      inbox_users.create!(user_id: uid)
    end
    reload
  end

  def assign_teams(team_ids)
    new_team_ids = Array(team_ids).map(&:to_s).reject(&:blank?).uniq
    current_ids = inbox_teams.pluck(:team_id).map(&:to_s)

    to_remove = current_ids - new_team_ids
    to_add = new_team_ids - current_ids

    inbox_teams.where(team_id: to_remove).destroy_all if to_remove.any?
    to_add.each do |tid|
      inbox_teams.create!(team_id: tid)
    end
    reload
  end

  def assigned_user_ids
    inbox_users.pluck(:user_id).map(&:to_s)
  end

  def assigned_team_ids
    inbox_teams.pluck(:team_id).map(&:to_s)
  end

  def collaborator_user_ids
    direct_ids = assigned_user_ids
    team_ids = assigned_team_ids
    if team_ids.any?
      team_user_ids = TeamUser.where(team_id: team_ids).pluck(:user_id).map(&:to_s)
      (direct_ids + team_user_ids).uniq
    else
      direct_ids
    end
  end

  def collaborator_users
    ids = collaborator_user_ids
    return User.none if ids.empty?

    User.where(id: ids)
  end

  def accessible_by?(user)
    return false unless user

    account_user = account.account_users.find_by(user_id: user.id)
    return false unless account_user
    return true if account_user.owner? || account_user.can?("inboxes.write")

    collaborator_user_ids.include?(user.id.to_s)
  end

  def user_ids=(ids)
    if persisted?
      assign_users(ids)
    else
      @pending_user_ids = ids
    end
  end

  def team_ids=(ids)
    if persisted?
      assign_teams(ids)
    else
      @pending_team_ids = ids
    end
  end

  private

  def sync_pending_assignments
    if @pending_user_ids.present?
      assign_users(@pending_user_ids)
      @pending_user_ids = nil
    end

    if @pending_team_ids.present?
      assign_teams(@pending_team_ids)
      @pending_team_ids = nil
    end
  end
end

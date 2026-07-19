# frozen_string_literal: true

module Teams
  class UpdateService < ApplicationService
    attr_reader :team, :params

    def initialize(team:, params:)
      @team = team
      @params = params
    end

    def call
      validate_feature_gate!

      ActiveRecord::Base.transaction do
        team.update!(team_params)
        sync_members if params.key?(:user_ids)
        sync_inboxes if params.key?(:inbox_ids)
        team.reload
      end
    end

    private

    def validate_feature_gate!
      return if team.account.feature_enabled?(:teams)

      raise(ActiveRecord::RecordNotSaved, "Teams feature is not enabled for this account")
    end

    def team_params
      params.slice(:name, :description, :auto_assign, :status, :configurations).compact
    end

    # Differential sync: only add/remove what changed, preserve existing records
    def sync_members
      new_user_ids = Array(params[:user_ids]).map(&:to_s)
      current_user_ids = team.team_users.pluck(:user_id).map(&:to_s)

      to_remove = current_user_ids - new_user_ids
      to_add = new_user_ids - current_user_ids

      team.team_users.where(user_id: to_remove).destroy_all if to_remove.any?

      to_add.each do |user_id|
        role = params[:lead_id].to_s == user_id ? :lead : :member
        team.team_users.create!(user_id: user_id, role: role)
      end

      # Sync lead role changes for existing members
      sync_lead_roles(new_user_ids) if params.key?(:lead_id)
    end

    def sync_lead_roles(user_ids)
      lead_id = params[:lead_id].to_s
      team.team_users.where(user_id: user_ids).find_each do |tu|
        expected_role = tu.user_id.to_s == lead_id ? "lead" : "member"
        tu.update!(role: expected_role) if tu.role != expected_role
      end
    end

    def sync_inboxes
      new_inbox_ids = Array(params[:inbox_ids]).map(&:to_s)
      current_inbox_ids = team.inbox_teams.pluck(:inbox_id).map(&:to_s)

      to_remove = current_inbox_ids - new_inbox_ids
      to_add = new_inbox_ids - current_inbox_ids

      team.inbox_teams.where(inbox_id: to_remove).destroy_all if to_remove.any?

      to_add.each do |inbox_id|
        team.inbox_teams.create!(inbox_id: inbox_id)
      end
    end
  end
end

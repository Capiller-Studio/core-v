# frozen_string_literal: true

module Teams
  class CreateService < ApplicationService
    attr_reader :account, :params

    def initialize(account:, params:)
      @account = account
      @params = params
    end

    def call
      validate_feature_gate!

      ShardRecord.transaction do
        team = build_team
        team.save!
        add_members(team)
        add_inboxes(team)
        team.reload
      end
    end

    private

    def validate_feature_gate!
      return if account.feature_enabled?(:teams)

      raise(ActiveRecord::RecordNotSaved, "Teams feature is not enabled for this account")
    end

    def build_team
      account.teams.new(
        team_params.merge(configurations: params[:configurations] || {})
      )
    end

    def team_params
      params.slice(:name, :description, :auto_assign, :status).compact
    end

    def add_members(team)
      return unless params[:user_ids].is_a?(Array)

      params[:user_ids].each do |user_id|
        role = params[:lead_id].to_s == user_id.to_s ? :lead : :member
        team.team_users.create!(user_id: user_id, role: role)
      end
    end

    def add_inboxes(team)
      return unless params[:inbox_ids].is_a?(Array)

      params[:inbox_ids].each do |inbox_id|
        team.inbox_teams.create!(inbox_id: inbox_id)
      end
    end
  end
end

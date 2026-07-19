# frozen_string_literal: true

module Teams
  class MemberService < ApplicationService
    attr_reader :team, :params

    def initialize(team:, params:)
      @team = team
      @params = params
    end

    def call
      case action
      when :add    then add_member
      when :remove then remove_member
      when :update_role then update_role
      else raise(ArgumentError, "Unknown action: #{action}")
      end
    end

    private

    def action
      params[:action]&.to_sym
    end

    def add_member
      team.team_users.create!(
        user_id: params[:user_id],
        role: params[:role] || :member
      )
    end

    def remove_member
      team_user = team.team_users.find_by!(user_id: params[:user_id])
      team_user.destroy!
    end

    def update_role
      team_user = team.team_users.find_by!(user_id: params[:user_id])
      team_user.update!(role: params[:role])
    end
  end
end

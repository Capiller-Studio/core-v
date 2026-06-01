# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    after_create_commit :auto_assign_agent, if: :should_auto_assign?
  end

  # --- Agent Assignment ---

  def assigned?
    assignee_id.present?
  end

  def assign!(user)
    ActiveRecord::Base.transaction do
      update!(assignee: user)

      # Ensure assignee is added as a participant so they can track unread/seen states
      conversation_members.find_or_create_by!(member: user, account: account) do |cm|
        cm.role = :participant
      end
    end
  end

  def unassign!
    update!(assignee: nil)
  end

  # --- Team Assignment ---

  def assign_team!(team)
    return if team_id == team&.id

    update!(team: team)
  end

  def unassign_team!
    return if team_id.nil?

    update!(team: nil)
  end

  def team_assigned?
    team_id.present?
  end

  private

  def should_auto_assign?
    inbox.auto_assign?
  end

  def auto_assign_agent
    AssignmentPolicies::Dispatcher.call(conversation: self)
  end
end
